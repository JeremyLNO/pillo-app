import UserNotifications

enum NotificationCategoryRegistrar {
    static let doseReminderCategoryID = "DOSE_REMINDER"
    static let takenActionID = "PILL_TAKEN"
    static let snoozeActionID = "PILL_SNOOZE"
    static let missedActionID = "PILL_MISSED"

    static let trustedContactCategoryID = "TRUSTED_CONTACT_ALERT"
    static let alertContactActionID = "ALERT_CONTACT"

    static func registerCategories() {
        let taken = UNNotificationAction(
            identifier: takenActionID,
            title: String(localized: "notification.action.taken"),
            options: []
        )
        let snooze = UNNotificationAction(
            identifier: snoozeActionID,
            title: String(localized: "notification.action.snooze"),
            options: []
        )
        let missed = UNNotificationAction(
            identifier: missedActionID,
            title: String(localized: "notification.action.missed"),
            options: [.destructive]
        )
        // OPEN_APP is the implicit default tap action (UNNotificationDefaultActionIdentifier) —
        // every reminder already opens the app on a plain tap, so it doesn't need its own button.
        let doseCategory = UNNotificationCategory(
            identifier: doseReminderCategoryID,
            actions: [taken, snooze, missed],
            intentIdentifiers: [],
            options: []
        )

        // `.foreground`: this action opens an SMS compose URL, which requires the app (and
        // then Messages) to come to the foreground — never sent silently in the background.
        let alertContact = UNNotificationAction(
            identifier: alertContactActionID,
            title: String(localized: "notification.action.alertContact"),
            options: [.foreground]
        )
        let trustedContactCategory = UNNotificationCategory(
            identifier: trustedContactCategoryID,
            actions: [alertContact],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([doseCategory, trustedContactCategory])
    }
}
