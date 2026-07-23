import SwiftUI
import UserNotifications

/// Spec section 20's "Notifications CrazyBeeLabs" settings block — deliberately separate
/// from "Rappels" (local pill reminders): update-availability and marketing pushes are
/// OneSignal-backed and opt-in, never required for the core reminder loop.
struct NotificationsCrazyBeeLabsSection: View {
    @Bindable var preferences: NotificationPreferences
    let oneSignal: OneSignalServicing
    let updateAvailability: UpdateAvailabilityServicing

    @State private var systemAuthorized = false
    @State private var optionalUpdate: UpdateCheckResult?

    var body: some View {
        Section(String(localized: "settings.onesignal.title")) {
            Toggle(String(localized: "settings.onesignal.updateNotifications"), isOn: $preferences.updateNotificationsEnabled)
                .onChange(of: preferences.updateNotificationsEnabled) { _, enabled in
                    if enabled { Task { await oneSignal.requestPushPermissionIfNeeded() } }
                }
            Toggle(String(localized: "settings.onesignal.marketing"), isOn: $preferences.marketingNotificationsEnabled)
                .onChange(of: preferences.marketingNotificationsEnabled) { _, enabled in
                    if enabled { Task { await oneSignal.requestPushPermissionIfNeeded() } }
                }

            HStack {
                Text("settings.onesignal.systemStatus")
                Spacer()
                Text(systemAuthorized ? String(localized: "settings.onesignal.authorized") : String(localized: "settings.onesignal.notAuthorized"))
                    .foregroundStyle(Palette.textSecondary)
            }
            Button(String(localized: "settings.onesignal.openSettings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }

            if let optionalUpdate {
                Link(destination: optionalUpdate.appStoreURL) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill").foregroundStyle(Palette.primary)
                        Text(String(format: String(localized: "settings.onesignal.updateAvailable"), optionalUpdate.latestVersion))
                    }
                }
            }
        }
        .task {
            systemAuthorized = await Self.currentAuthorization()
            optionalUpdate = await updateAvailability.checkForUpdate()
        }
    }

    private static func currentAuthorization() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
}
