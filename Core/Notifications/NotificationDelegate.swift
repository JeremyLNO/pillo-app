import Foundation
import SwiftData
import UserNotifications
import UIKit

/// Owns the system notification-center delegate. Holds the `ModelContainer` (not a
/// `ModelContext`, which only exists inside the SwiftUI environment) because this object
/// is created once at app launch, independent of any view. All work happens inside a
/// `Task { @MainActor in ... }` since `ModelContext` isn't `Sendable`; `completionHandler`
/// is called promptly rather than after awaiting the full write — an accepted, deliberate
/// small race for Phase 1 rather than a silently-glossed-over one.
@MainActor
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    private let container: ModelContainer
    private let router: DeepLinkRouterServicing
    private let reminderCounterStore: ReminderCounterStore

    init(container: ModelContainer, router: DeepLinkRouterServicing, reminderCounterStore: ReminderCounterStore) {
        self.container = container
        self.router = router
        self.reminderCounterStore = reminderCounterStore
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void
    ) {
        let identifier = notification.request.identifier
        // Parsed into plain Sendable values here (still in the nonisolated context) rather
        // than carrying the non-Sendable `[AnyHashable: Any]` userInfo dictionary across
        // the Task boundary below.
        let doseEventID = Self.parseDoseEventID(from: notification.request.content.userInfo)
        if identifier.contains(".snooze."), let doseEventID {
            Task { @MainActor in
                reminderCounterStore.increment(for: doseEventID)
            }
        }
        completionHandler([.banner, .sound, .badge])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        let profileID = (userInfo["profileID"] as? String).flatMap(UUID.init)
        let doseEventID = (userInfo["doseEventID"] as? String).flatMap(UUID.init)
        Task { @MainActor in
            defer { completionHandler() }
            await self.handle(actionIdentifier: actionIdentifier, profileID: profileID, doseEventID: doseEventID)
        }
    }

    private nonisolated static func parseDoseEventID(from userInfo: [AnyHashable: Any]) -> UUID? {
        (userInfo["doseEventID"] as? String).flatMap(UUID.init)
    }

    private func handle(actionIdentifier: String, profileID: UUID?, doseEventID: UUID?) async {
        guard let profileID, let doseEventID else {
            if actionIdentifier == UNNotificationDefaultActionIdentifier {
                router.pendingRoute = .home
            }
            return
        }

        let context = container.mainContext
        guard
            let profile = try? context.fetch(FetchDescriptor<PillProfile>(predicate: #Predicate { $0.id == profileID })).first,
            let event = try? context.fetch(FetchDescriptor<DoseEvent>(predicate: #Predicate { $0.id == doseEventID })).first
        else { return }

        let notificationService = LocalNotificationService()
        let trackingService = DoseTrackingService(context: context, notificationService: notificationService)
        let scheduleService = PillScheduleService(context: context)

        switch actionIdentifier {
        case NotificationCategoryRegistrar.takenActionID:
            try? trackingService.confirmDose(event, profile: profile, takenAt: .now)
        case NotificationCategoryRegistrar.missedActionID:
            try? trackingService.markMissed(event)
        case NotificationCategoryRegistrar.snoozeActionID:
            break // the follow-up reminders were already pre-scheduled by refreshSchedule
        case NotificationCategoryRegistrar.alertContactActionID:
            await openTrustedContactMessage(context: context)
        case UNNotificationDefaultActionIdentifier:
            router.pendingRoute = .home
        default:
            break
        }

        if let events = try? scheduleService.doseEvents(for: profile),
           let preferences = try? context.fetch(FetchDescriptor<NotificationPreferences>()).first {
            await notificationService.refreshSchedule(for: profile, events: events, preferences: preferences)
        }
    }

    /// Opens the Messages app with an SMS pre-filled to the user's designated trusted
    /// contact — never sent automatically. The user still has to review and tap Send
    /// themselves inside Messages; Pillo has no way to send anything on its own.
    private func openTrustedContactMessage(context: ModelContext) async {
        guard let preferences = try? context.fetch(FetchDescriptor<NotificationPreferences>()).first,
              let phone = preferences.trustedContactPhoneNumber, !phone.isEmpty
        else { return }

        let sanitizedPhone = phone.filter { $0.isNumber || $0 == "+" }
        let body = String(localized: "trustedContact.message.body")
        guard let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "sms:\(sanitizedPhone)&body=\(encodedBody)")
        else { return }

        _ = await UIApplication.shared.open(url)
    }
}
