import Foundation
import SwiftUI
import SwiftData

/// Bundles every concrete service behind its protocol. Built once by `PilloApp` and
/// handed to the view tree via the environment; tests instead construct individual
/// services directly with an in-memory `ModelContext`, bypassing this container entirely.
@MainActor
final class ServiceContainer {
    let context: ModelContext
    let pillSchedule: PillScheduleServicing
    let doseTracking: DoseTrackingServicing
    let localNotification: LocalNotificationServicing
    let localization: LocalizationServicing
    let biometricLock: BiometricLockServicing
    let ruleEngine: RuleEngineServicing
    let stock: StockServicing
    let deepLinkRouter: DeepLinkRouterServicing
    let reminderCounterStore: ReminderCounterStore
    let configuration: AppConfiguration
    let oneSignal: OneSignalServicing
    let updateAvailability: UpdateAvailabilityServicing
    let reviewRequest: ReviewRequestServicing
    let dataExport: DataExportServicing
    let historyExport: HistoryExportServicing
    let appLock: AppLockServicing
    let watchConnectivity: WatchConnectivityServicing

    init(context: ModelContext, userPreferences: UserPreferences, configuration: AppConfiguration = .current) {
        self.context = context
        self.configuration = configuration

        let notification = LocalNotificationService()
        self.localNotification = notification
        self.pillSchedule = PillScheduleService(context: context)
        self.doseTracking = DoseTrackingService(context: context, notificationService: notification)
        let localizationService = LocalizationService(context: context, preferences: userPreferences)
        self.localization = localizationService
        self.biometricLock = BiometricLockService()
        self.ruleEngine = FallbackRuleEngine()
        self.stock = StockService(context: context)
        let router = DeepLinkRouter(supportURL: configuration.crazyBeeSupportURL)
        self.deepLinkRouter = router
        self.reminderCounterStore = ReminderCounterStore()
        self.oneSignal = OneSignalService(router: router)
        self.updateAvailability = UpdateAvailabilityService(
            remoteConfigURL: configuration.remoteConfigURL,
            currentLanguage: { [weak localizationService] in localizationService?.currentLanguage ?? .en }
        )
        self.reviewRequest = ReviewRequestService()
        self.dataExport = DataExportService(context: context)
        self.historyExport = HistoryExportService()
        self.appLock = AppLockService()
        let watchConnectivity = WatchConnectivityService()
        watchConnectivity.activate()
        self.watchConnectivity = watchConnectivity
    }
}

private struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue: ServiceContainer? = nil
}

extension EnvironmentValues {
    var services: ServiceContainer? {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
