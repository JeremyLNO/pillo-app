import Foundation
import UserNotifications

@MainActor
final class LocalNotificationService: LocalNotificationServicing {
    private let center = UNUserNotificationCenter.current()

    /// Base sliding-window size; shrunk when `maximumReminderCount` is high so the total
    /// pending-request count (primary + snoozes, per day, times window) stays well under
    /// iOS's 64-pending-local-notification ceiling.
    private func windowDays(maximumReminderCount: Int) -> Int {
        min(14, max(3, 60 / (1 + max(0, maximumReminderCount))))
    }

    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func refreshSchedule(for profile: PillProfile, events: [DoseEvent], preferences: NotificationPreferences) async {
        guard preferences.remindersEnabled else {
            await cancelAllReminders(for: profile)
            return
        }
        guard await requestAuthorizationIfNeeded() else { return }

        // `events` already contains this profile's full history (past + future) — reused
        // as-is to learn the adaptive offset, no extra fetch needed. Note: because the
        // diffing below only adds missing identifiers and never rewrites an already-pending
        // one, an offset that changes between refreshes only takes effect on doses that
        // aren't already scheduled yet — same eventual-consistency tradeoff every other
        // preference (message, sound...) already has here.
        let adaptiveOffsetMinutes = preferences.adaptiveReminderEnabled
            ? (AdaptiveReminderCalculator.suggestedOffsetMinutes(from: events) ?? 0)
            : 0

        let windowEnd = Calendar.current.date(byAdding: .day, value: windowDays(maximumReminderCount: preferences.maximumReminderCount), to: .now) ?? .now
        let eligible = events.filter { event in
            (event.status == .scheduled || event.status == .placebo)
                && event.scheduledDateTime > .now
                && event.scheduledDateTime <= windowEnd
        }

        let snoozeOffsets = Array(preferences.snoozeIntervals.prefix(max(0, preferences.maximumReminderCount)))
        var desiredRequests: [UNNotificationRequest] = []
        for event in eligible {
            let anchor = event.scheduledDateTime.addingTimeInterval(TimeInterval(adaptiveOffsetMinutes * 60))
            desiredRequests.append(makeRequest(for: event, profile: profile, preferences: preferences, fireDate: anchor, kind: .primary))
            for (index, offset) in snoozeOffsets.enumerated() {
                desiredRequests.append(makeRequest(for: event, profile: profile, preferences: preferences, fireDate: anchor.addingTimeInterval(TimeInterval(offset * 60)), kind: .snooze(index)))
            }
            if preferences.trustedContactEnabled, let phone = preferences.trustedContactPhoneNumber, !phone.isEmpty {
                let alertDate = event.scheduledDateTime.addingTimeInterval(TimeInterval(preferences.trustedContactAlertDelayHours * 3600))
                desiredRequests.append(makeRequest(for: event, profile: profile, preferences: preferences, fireDate: alertDate, kind: .trustedContact))
            }
        }

        let desiredIDs = Set(desiredRequests.map(\.identifier))
        let pending = await center.pendingNotificationRequests()
        let ourPendingIDs = Set(pending.map(\.identifier).filter { $0.hasPrefix(profile.id.uuidString) })

        let idsToRemove = ourPendingIDs.subtracting(desiredIDs)
        if !idsToRemove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: Array(idsToRemove))
        }

        let existingIDsAfterRemoval = ourPendingIDs.subtracting(idsToRemove)
        let requestsToAdd = desiredRequests.filter { !existingIDsAfterRemoval.contains($0.identifier) }
        for request in requestsToAdd {
            try? await center.add(request)
        }
    }

    func cancelReminders(for event: DoseEvent) async {
        let pending = await center.pendingNotificationRequests()
        let prefix = "\(event.pillProfileID.uuidString).\(event.id.uuidString)."
        let idsToRemove = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
    }

    func cancelAllReminders(for profile: PillProfile) async {
        let pending = await center.pendingNotificationRequests()
        let idsToRemove = pending.map(\.identifier).filter { $0.hasPrefix(profile.id.uuidString) }
        center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
    }

    private enum RequestKind {
        case primary
        case snooze(Int)
        case trustedContact

        var identifierSuffix: String {
            switch self {
            case .primary: return "primary"
            case .snooze(let index): return "snooze.\(index)"
            case .trustedContact: return "trustedContact"
            }
        }
    }

    private func makeRequest(for event: DoseEvent, profile: PillProfile, preferences: NotificationPreferences, fireDate: Date, kind: RequestKind) -> UNNotificationRequest {
        let identifier = "\(event.pillProfileID.uuidString).\(event.id.uuidString).\(kind.identifierSuffix)"

        let content = UNMutableNotificationContent()
        switch kind {
        case .primary, .snooze:
            content.title = String(localized: "notification.reminder.title")
            content.body = preferences.reminderMessage?.isEmpty == false
                ? preferences.reminderMessage!
                : String(localized: "notification.reminder.body.default")
            content.categoryIdentifier = NotificationCategoryRegistrar.doseReminderCategoryID
            content.sound = preferences.soundEnabled ? .default : nil
            if preferences.badgeEnabled {
                content.badge = 1
            }
        case .trustedContact:
            content.title = String(localized: "notification.trustedContact.title")
            content.body = String(localized: "notification.trustedContact.body")
            content.categoryIdentifier = NotificationCategoryRegistrar.trustedContactCategoryID
            content.sound = preferences.soundEnabled ? .default : nil
        }
        content.userInfo = [
            "profileID": event.pillProfileID.uuidString,
            "doseEventID": event.id.uuidString,
        ]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
}
