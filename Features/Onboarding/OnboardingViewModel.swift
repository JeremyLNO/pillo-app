import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class OnboardingViewModel {
    enum Step: Int, CaseIterable {
        case intro, pillSetup, notifications, privacy
    }

    var step: Step = .intro

    // Pill setup fields
    var displayName: String = ""
    var brandName: String = ""
    var pillType: PillType = .combined
    var scheduleType: ScheduleType = .days21Active7Stop
    var activePillCount: Int = 21
    var placeboPillCount: Int = 7
    var usualIntakeTime: Date = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: .now) ?? .now
    var startDate: Date = .now
    var allowedDelayMinutes: Int = 720

    // Notifications
    var notificationsAuthorized = false
    var didRequestNotifications = false

    // Privacy
    var biometricLockEnabled = false
    var discreetModeEnabled = false
    var customReminderMessage: String = ""

    var canAdvanceFromPillSetup: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty && activePillCount > 0
    }

    func goNext() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    func requestNotificationPermission(services: ServiceContainer) async {
        didRequestNotifications = true
        notificationsAuthorized = await services.localNotification.requestAuthorizationIfNeeded()
    }

    func complete(services: ServiceContainer, context: ModelContext, userPreferences: UserPreferences) {
        let cycleLength = activePillCount + placeboPillCount
        let profile = PillProfile(
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            brandName: brandName.isEmpty ? nil : brandName,
            pillType: pillType,
            activePillCount: activePillCount,
            placeboPillCount: placeboPillCount,
            cycleLength: scheduleType == .continuous ? activePillCount : cycleLength,
            scheduleType: scheduleType,
            usualIntakeTime: usualIntakeTime,
            startDate: startDate,
            allowedDelayMinutes: allowedDelayMinutes,
            continuousUse: scheduleType == .continuous
        )
        context.insert(profile)

        let notificationPreferences = NotificationPreferences(
            reminderMessage: customReminderMessage.isEmpty ? nil : customReminderMessage,
            notificationPrivacyMode: discreetModeEnabled ? .discreet : .standard
        )
        context.insert(notificationPreferences)

        context.insert(StockEntry())

        userPreferences.completedOnboarding = true
        userPreferences.biometricLockEnabled = biometricLockEnabled
        userPreferences.discreetModeEnabled = discreetModeEnabled
        userPreferences.lastKnownTimeZoneIdentifier = TimeZone.current.identifier

        try? context.save()

        try? services.pillSchedule.ensureDoseEvents(for: profile, from: startDate, cyclesToGenerate: 2)

        if let events = try? services.pillSchedule.doseEvents(for: profile) {
            Task {
                await services.localNotification.refreshSchedule(for: profile, events: events, preferences: notificationPreferences)
            }
        }
    }
}
