import Foundation

/// Result of locating a calendar day within a pill profile's cycle.
struct PackPosition: Equatable, Sendable {
    /// 0-based index of the pack/cycle (0 = the pack containing `startDate`).
    let packIndex: Int
    /// 1-based day within the pack, e.g. "Jour 12/28".
    let dayInPack: Int
    let packSize: Int
}

@MainActor
protocol PillScheduleServicing {
    /// Generates (and persists) any missing `DoseEvent`s for `profile` covering
    /// `cyclesToGenerate` cycles starting from `date`. Idempotent: existing events for
    /// the same `(pillProfileID, scheduledDate)` are never duplicated.
    @discardableResult
    func ensureDoseEvents(for profile: PillProfile, from date: Date, cyclesToGenerate: Int) throws -> [DoseEvent]

    /// The next upcoming (or currently due) dose for `profile`, generating more events
    /// if the existing window has been exhausted.
    func nextDose(for profile: PillProfile, after date: Date) throws -> DoseEvent?

    func packPosition(for date: Date, profile: PillProfile) -> PackPosition

    /// All dose events for `profile` in ascending scheduled-date order.
    func doseEvents(for profile: PillProfile) throws -> [DoseEvent]

    /// The date of the next placebo/break day after `date` (nil for schedules with no break).
    func nextBreakDate(for profile: PillProfile, after date: Date) -> Date?

    /// The date the next pack/cycle begins after `date` — used as the "next pack" banner
    /// fallback for schedules with no break (28-pill, continuous).
    func nextPackStartDate(for profile: PillProfile, after date: Date) -> Date
}
