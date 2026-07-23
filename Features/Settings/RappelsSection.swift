import SwiftUI
import UIKit

struct RappelsSection: View {
    @Bindable var preferences: NotificationPreferences

    var body: some View {
        Section(String(localized: "settings.reminders.title")) {
            Toggle(String(localized: "settings.reminders.enabled"), isOn: $preferences.remindersEnabled)

            if preferences.remindersEnabled {
                DatePicker(String(localized: "settings.reminders.time"), selection: $preferences.primaryReminderTime, displayedComponents: .hourAndMinute)

                Stepper(value: $preferences.maximumReminderCount, in: 0...5) {
                    Text(String(format: String(localized: "settings.reminders.maxCount"), preferences.maximumReminderCount))
                }

                Toggle(String(localized: "settings.reminders.sound"), isOn: $preferences.soundEnabled)
                Toggle(String(localized: "settings.reminders.badge"), isOn: $preferences.badgeEnabled)

                VStack(alignment: .leading, spacing: 6) {
                    Text(String(localized: "settings.reminders.customMessage"))
                        .font(Typography.caption)
                        .foregroundStyle(Palette.textSecondary)
                    TextField(
                        String(localized: "notification.reminder.body.default"),
                        text: Binding(
                            get: { preferences.reminderMessage ?? "" },
                            set: { preferences.reminderMessage = $0.isEmpty ? nil : $0 }
                        )
                    )
                }

                Toggle(String(localized: "settings.reminders.discreet"), isOn: Binding(
                    get: { preferences.notificationPrivacyMode == .discreet },
                    set: { preferences.notificationPrivacyMode = $0 ? .discreet : .standard }
                ))

                VStack(alignment: .leading, spacing: 6) {
                    Toggle(String(localized: "settings.reminders.adaptive"), isOn: $preferences.adaptiveReminderEnabled)
                    Text("settings.reminders.adaptive.footer")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.textSecondary)
                }

                Button {
                    if let url = URL(string: "shortcuts://") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("settings.reminders.addToSiri")
                }
            }
        }
    }
}
