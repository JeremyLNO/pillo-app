import Foundation

/// Pure, unit-testable logic for the adaptive-reminder feature: suggests how many minutes
/// to shift the primary reminder later, learned from how late the last several confirmed
/// doses actually were. Deliberately conservative — only returns a non-nil suggestion when
/// there's enough history and it's consistent enough to trust, so a single noisy day never
/// yanks the reminder time around.
enum AdaptiveReminderCalculator {
    static let minimumSampleSize = 5
    static let maximumOffsetMinutes = 120
    /// Reject the suggestion if the recent delays are too spread out (interquartile range)
    /// to represent a real habit rather than noise.
    static let maximumInterquartileRangeMinutes = 45

    /// `history` is expected to be every `DoseEvent` for the profile (as already returned by
    /// `PillScheduleService.doseEvents(for:)`), mixing past and future events — only the most
    /// recent confirmed ones are used.
    static func suggestedOffsetMinutes(from history: [DoseEvent], sampleSize: Int = 10) -> Int? {
        let delays = history
            .filter { $0.actualTakenDate != nil && ($0.status == .takenOnTime || $0.status == .takenLate) }
            .sorted { $0.scheduledDateTime > $1.scheduledDateTime }
            .prefix(sampleSize)
            .map(\.delayMinutes)
            .sorted()

        guard delays.count >= minimumSampleSize else { return nil }

        let median = delays[delays.count / 2]
        guard median > 0 else { return nil }

        let q1 = delays[delays.count / 4]
        let q3 = delays[(delays.count * 3) / 4]
        guard (q3 - q1) <= maximumInterquartileRangeMinutes else { return nil }

        return min(median, maximumOffsetMinutes)
    }
}
