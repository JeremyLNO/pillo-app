import Foundation
import SwiftData

@MainActor
final class DoseTrackingService: DoseTrackingServicing {
    private let context: ModelContext
    private let notificationService: LocalNotificationServicing?

    init(context: ModelContext, notificationService: LocalNotificationServicing? = nil) {
        self.context = context
        self.notificationService = notificationService
    }

    @discardableResult
    func confirmDose(_ event: DoseEvent, profile: PillProfile, takenAt: Date = .now) throws -> DoseEvent {
        event.actualTakenDate = takenAt
        let delta = takenAt.timeIntervalSince(event.scheduledDateTime)
        let delayMinutes = max(0, Int(delta / 60))
        event.delayMinutes = delayMinutes
        if event.status != .placebo {
            event.status = delayMinutes <= profile.allowedDelayMinutes ? .takenOnTime : .takenLate
        }
        event.updatedAt = .now
        try context.save()
        Task { await notificationService?.cancelReminders(for: event) }
        NotificationCenter.default.post(name: DoseChangeNotifying.name, object: nil)
        return event
    }

    @discardableResult
    func undoConfirmation(_ event: DoseEvent) throws -> DoseEvent {
        event.actualTakenDate = nil
        event.delayMinutes = 0
        event.status = event.status == .placebo ? .placebo : .scheduled
        event.updatedAt = .now
        try context.save()
        NotificationCenter.default.post(name: DoseChangeNotifying.name, object: nil)
        return event
    }

    @discardableResult
    func markMissed(_ event: DoseEvent) throws -> DoseEvent {
        event.status = .missed
        event.updatedAt = .now
        try context.save()
        Task { await notificationService?.cancelReminders(for: event) }
        NotificationCenter.default.post(name: DoseChangeNotifying.name, object: nil)
        return event
    }

    @discardableResult
    func correctDose(_ event: DoseEvent, profile: PillProfile, takenAt: Date?, note: String?) throws -> DoseEvent {
        event.actualTakenDate = takenAt
        event.userNote = note
        if let takenAt {
            let delta = takenAt.timeIntervalSince(event.scheduledDateTime)
            let delayMinutes = max(0, Int(delta / 60))
            event.delayMinutes = delayMinutes
            if event.status != .placebo {
                event.status = delayMinutes <= profile.allowedDelayMinutes ? .takenOnTime : .takenLate
            }
        } else {
            event.delayMinutes = 0
            event.status = event.status == .placebo ? .placebo : .scheduled
        }
        event.updatedAt = .now
        try context.save()
        NotificationCenter.default.post(name: DoseChangeNotifying.name, object: nil)
        return event
    }
}
