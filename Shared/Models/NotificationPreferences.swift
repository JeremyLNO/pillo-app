import Foundation
import SwiftData

@Model
final class NotificationPreferences {
    @Attribute(.unique) var id: UUID
    var remindersEnabled: Bool
    var reminderMessage: String?
    var notificationPrivacyModeRaw: String
    var primaryReminderTime: Date
    /// Minutes after the primary reminder at which snooze/follow-up reminders fire, e.g. [5, 10, 15, 30, 60].
    var snoozeIntervals: [Int]
    var maximumReminderCount: Int
    var soundEnabled: Bool
    var badgeEnabled: Bool
    /// Architecture only: never enabled without Apple's Critical Alerts entitlement being granted.
    var criticalAlertsEnabled: Bool
    var remoteNotificationsEnabled: Bool
    var updateNotificationsEnabled: Bool
    var marketingNotificationsEnabled: Bool
    /// Additive field (see Enums.TimeZoneChangeStrategy) — required for section 16 of the spec.
    var timeZoneChangeStrategyRaw: String
    /// Opt-in: shift the primary reminder later by the median delay of recent confirmed
    /// doses (see `AdaptiveReminderCalculator`), instead of always firing at the raw
    /// scheduled time.
    var adaptiveReminderEnabled: Bool
    /// Opt-in, local-only "trusted contact" safety net: never sent automatically — only
    /// pre-fills an SMS the user must explicitly tap Send on, after `trustedContactAlertDelayHours`
    /// of a dose still being unconfirmed.
    var trustedContactEnabled: Bool
    var trustedContactName: String?
    var trustedContactPhoneNumber: String?
    var trustedContactAlertDelayHours: Int

    var notificationPrivacyMode: NotificationPrivacyMode {
        get { NotificationPrivacyMode(rawValue: notificationPrivacyModeRaw) ?? .standard }
        set { notificationPrivacyModeRaw = newValue.rawValue }
    }

    var timeZoneChangeStrategy: TimeZoneChangeStrategy {
        get { TimeZoneChangeStrategy(rawValue: timeZoneChangeStrategyRaw) ?? .askEachTime }
        set { timeZoneChangeStrategyRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        remindersEnabled: Bool = true,
        reminderMessage: String? = nil,
        notificationPrivacyMode: NotificationPrivacyMode = .standard,
        primaryReminderTime: Date = .now,
        snoozeIntervals: [Int] = [5, 10, 15, 30, 60],
        maximumReminderCount: Int = 3,
        soundEnabled: Bool = true,
        badgeEnabled: Bool = true,
        criticalAlertsEnabled: Bool = false,
        remoteNotificationsEnabled: Bool = false,
        updateNotificationsEnabled: Bool = true,
        marketingNotificationsEnabled: Bool = false,
        timeZoneChangeStrategy: TimeZoneChangeStrategy = .askEachTime,
        adaptiveReminderEnabled: Bool = false,
        trustedContactEnabled: Bool = false,
        trustedContactName: String? = nil,
        trustedContactPhoneNumber: String? = nil,
        trustedContactAlertDelayHours: Int = 3
    ) {
        self.id = id
        self.remindersEnabled = remindersEnabled
        self.reminderMessage = reminderMessage
        self.notificationPrivacyModeRaw = notificationPrivacyMode.rawValue
        self.primaryReminderTime = primaryReminderTime
        self.snoozeIntervals = snoozeIntervals
        self.maximumReminderCount = maximumReminderCount
        self.soundEnabled = soundEnabled
        self.badgeEnabled = badgeEnabled
        self.criticalAlertsEnabled = criticalAlertsEnabled
        self.remoteNotificationsEnabled = remoteNotificationsEnabled
        self.updateNotificationsEnabled = updateNotificationsEnabled
        self.marketingNotificationsEnabled = marketingNotificationsEnabled
        self.timeZoneChangeStrategyRaw = timeZoneChangeStrategy.rawValue
        self.adaptiveReminderEnabled = adaptiveReminderEnabled
        self.trustedContactEnabled = trustedContactEnabled
        self.trustedContactName = trustedContactName
        self.trustedContactPhoneNumber = trustedContactPhoneNumber
        self.trustedContactAlertDelayHours = trustedContactAlertDelayHours
    }
}
