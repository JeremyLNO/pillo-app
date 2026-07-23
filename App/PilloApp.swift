import SwiftUI
import SwiftData
import UserNotifications

@main
struct PilloApp: App {
    private let container: ModelContainer
    private let services: ServiceContainer
    private let notificationDelegate: NotificationDelegate

    init() {
        let launchArguments = ProcessInfo.processInfo.arguments
        let container: ModelContainer
        if launchArguments.contains("-demoSeed") {
            container = PersistenceController.preview()
        } else {
            container = PersistenceController.make(fresh: launchArguments.contains("-freshInstall"))
        }
        self.container = container

        let context = container.mainContext
        let preferences = Self.fetchOrCreateUserPreferences(in: context)
        let services = ServiceContainer(context: context, userPreferences: preferences)
        self.services = services

        NotificationCategoryRegistrar.registerCategories()
        let delegate = NotificationDelegate(
            container: container,
            router: services.deepLinkRouter,
            reminderCounterStore: services.reminderCounterStore
        )
        self.notificationDelegate = delegate
        UNUserNotificationCenter.current().delegate = delegate

        BackgroundRefreshTask.register(container: container)

        // OneSignal is initialized unconditionally (no-ops if ONESIGNAL_APP_ID is still
        // the TODO placeholder) — it only ever carries technical tags, never health data.
        services.oneSignal.initialize(appId: services.configuration.oneSignalAppID)
        let notificationPreferences = Self.fetchOrCreateNotificationPreferences(in: context)
        services.oneSignal.syncTechnicalTags(
            appVersion: (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0",
            language: services.localization.currentLanguage.rawValue,
            environment: services.configuration.environment.rawValue,
            updateNotificationsConsent: notificationPreferences.updateNotificationsEnabled,
            marketingConsent: notificationPreferences.marketingNotificationsEnabled
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.services, services)
                .environment(\.locale, services.localization.currentLanguage.locale)
        }
        .modelContainer(container)
    }

    @MainActor
    private static func fetchOrCreateUserPreferences(in context: ModelContext) -> UserPreferences {
        if let existing = try? context.fetch(FetchDescriptor<UserPreferences>()).first {
            return existing
        }
        let created = UserPreferences()
        context.insert(created)
        try? context.save()
        return created
    }

    @MainActor
    private static func fetchOrCreateNotificationPreferences(in context: ModelContext) -> NotificationPreferences {
        if let existing = try? context.fetch(FetchDescriptor<NotificationPreferences>()).first {
            return existing
        }
        let created = NotificationPreferences()
        context.insert(created)
        try? context.save()
        return created
    }
}
