import Foundation

@MainActor
protocol DoseTrackingServicing {
    /// Confirms a dose was taken at `takenAt` (defaults to now), computing delay/status
    /// against `profile.allowedDelayMinutes`. Placebo doses keep `.placebo` status but
    /// still record `actualTakenDate` so the blister grid shows a checkmark.
    @discardableResult
    func confirmDose(_ event: DoseEvent, profile: PillProfile, takenAt: Date) throws -> DoseEvent

    /// Reverts an accidental confirmation back to `.scheduled`/`.placebo`.
    @discardableResult
    func undoConfirmation(_ event: DoseEvent) throws -> DoseEvent

    /// Explicitly marks a dose as missed (used by the notification's "Oubliée" action
    /// and by the missed-pill assistant).
    @discardableResult
    func markMissed(_ event: DoseEvent) throws -> DoseEvent

    /// Corrects a past dose's actual-taken time and note (used by "Corriger une prise passée").
    @discardableResult
    func correctDose(_ event: DoseEvent, profile: PillProfile, takenAt: Date?, note: String?) throws -> DoseEvent
}
