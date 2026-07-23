import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var isConfirming = false
    var lastConfirmedEventID: UUID?

    func confirm(event: DoseEvent, profile: PillProfile, services: ServiceContainer) {
        guard !isConfirming else { return }
        isConfirming = true
        defer { isConfirming = false }
        try? services.doseTracking.confirmDose(event, profile: profile, takenAt: .now)
        lastConfirmedEventID = event.id
    }

    func undoLastConfirmation(event: DoseEvent, services: ServiceContainer) {
        try? services.doseTracking.undoConfirmation(event)
        lastConfirmedEventID = nil
    }

    func reportSnooze(event: DoseEvent, services: ServiceContainer) {
        services.reminderCounterStore.increment(for: event.id)
    }

    func canStillSnooze(event: DoseEvent, preferences: NotificationPreferences, services: ServiceContainer) -> Bool {
        services.reminderCounterStore.count(for: event.id) < preferences.maximumReminderCount
    }
}
