import BackgroundTasks
import SwiftData

/// Architecture-only in Phase 1: registers a `BGAppRefreshTask` so the notification
/// sliding window can be topped up roughly every ~12h even if the user hasn't opened
/// the app, without depending on any server. No retry/backoff policy yet — that's a
/// later-phase refinement once this has real-device telemetry to tune against.
enum BackgroundRefreshTask {
    static let identifier = "com.lno.pillo.refresh"

    static func register(container: ModelContainer) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handle(refreshTask, container: container)
        }
    }

    static func scheduleNext() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 12, to: .now)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGAppRefreshTask, container: ModelContainer) {
        scheduleNext()
        // BGTaskScheduler hands us exclusive ownership of `task` for this task's lifetime,
        // but BGAppRefreshTask predates Sendable — nonisolated(unsafe) documents that
        // exclusivity contract to the compiler instead of fighting the region checker.
        nonisolated(unsafe) let capturedTask = task
        Task {
            await refreshAllProfiles(container: container)
            capturedTask.setTaskCompleted(success: true)
        }
    }

    @MainActor
    private static func refreshAllProfiles(container: ModelContainer) async {
        let context = container.mainContext
        let scheduleService = PillScheduleService(context: context)
        let notificationService = LocalNotificationService()
        let profiles = (try? context.fetch(FetchDescriptor<PillProfile>(predicate: #Predicate { $0.isActive }))) ?? []
        let preferences = (try? context.fetch(FetchDescriptor<NotificationPreferences>()).first) ?? NotificationPreferences()
        for profile in profiles {
            if let events = try? scheduleService.doseEvents(for: profile) {
                await notificationService.refreshSchedule(for: profile, events: events, preferences: preferences)
            }
        }
    }
}
