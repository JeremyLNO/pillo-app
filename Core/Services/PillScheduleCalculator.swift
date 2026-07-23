import Foundation

/// Sendable, value-type description of one custom-schedule day (mirrors `CustomScheduleDay`
/// without depending on the SwiftData model type, so the calculator stays a pure,
/// non-isolated struct callable from any actor, including a future background-refresh task).
struct CustomDayInput: Sendable, Equatable {
    let dayIndex: Int
    let isActivePillDay: Bool
    let isPlaceboDay: Bool
}

/// Sendable snapshot of the profile fields the calculator actually needs. Kept separate
/// from the `PillProfile` SwiftData model (a MainActor-isolated reference type) so the
/// calculator has zero persistence dependency and is trivially unit-testable. Callers
/// (MainActor services) build this from a `PillProfile` explicitly rather than the
/// struct reaching into the model itself, keeping this type free of any actor hop.
struct PillScheduleInput: Sendable, Equatable {
    let profileID: UUID
    let scheduleType: ScheduleType
    let startDate: Date
    let activePillCount: Int
    let placeboPillCount: Int
    let usualIntakeTime: Date
    let customDays: [CustomDayInput]

    init(
        profileID: UUID,
        scheduleType: ScheduleType,
        startDate: Date,
        activePillCount: Int,
        placeboPillCount: Int,
        usualIntakeTime: Date,
        customDays: [CustomDayInput] = []
    ) {
        self.profileID = profileID
        self.scheduleType = scheduleType
        self.startDate = startDate
        self.activePillCount = activePillCount
        self.placeboPillCount = placeboPillCount
        self.usualIntakeTime = usualIntakeTime
        self.customDays = customDays
    }
}

/// One day's outcome: nothing to take, an active pill, or a placebo pill.
private enum DayKind: Equatable {
    case none
    case active
    case placebo
}

/// Pure date/schedule math, deliberately free of SwiftData/ModelContext so it can run on
/// any actor (including inside a background-refresh task) without Sendable friction.
struct PillScheduleCalculator: Sendable {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func cycleLength(for input: PillScheduleInput) -> Int {
        switch input.scheduleType {
        case .days21Active7Stop, .days24Active4Placebo:
            return max(1, input.activePillCount + input.placeboPillCount)
        case .days28:
            return max(1, input.activePillCount + input.placeboPillCount)
        case .continuous:
            return max(1, input.activePillCount)
        case .custom:
            return max(1, input.customDays.count)
        }
    }

    /// Whole calendar days between two dates (DST-safe: compares start-of-day, not raw intervals).
    func dayIndex(for date: Date, startDate: Date) -> Int {
        let startOfStart = calendar.startOfDay(for: startDate)
        let startOfDate = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: startOfStart, to: startOfDate).day ?? 0
    }

    func packPosition(for date: Date, input: PillScheduleInput) -> PackPosition {
        let length = cycleLength(for: input)
        let absoluteIndex = dayIndex(for: date, startDate: input.startDate)
        let normalizedIndex = ((absoluteIndex % length) + length) % length
        let packIndex = absoluteIndex >= 0 ? absoluteIndex / length : -(((-absoluteIndex) + length - 1) / length)
        return PackPosition(packIndex: packIndex, dayInPack: normalizedIndex + 1, packSize: length)
    }

    /// Generates draft dose events for every calendar day from `fromDate` (inclusive) through
    /// `cyclesToGenerate` full cycles. Callers are responsible for de-duplicating against
    /// already-persisted events (by `pillProfileID` + `scheduledDate`) before inserting.
    func generateDrafts(input: PillScheduleInput, from fromDate: Date, cyclesToGenerate: Int) -> [DoseEventDraft] {
        let length = cycleLength(for: input)
        let totalDays = max(length, length * max(1, cyclesToGenerate))
        let startOfFrom = calendar.startOfDay(for: fromDate)

        var drafts: [DoseEventDraft] = []
        drafts.reserveCapacity(totalDays)

        for offset in 0..<totalDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfFrom) else { continue }
            let absoluteIndex = dayIndex(for: day, startDate: input.startDate)
            let normalizedIndex = ((absoluteIndex % length) + length) % length
            let kind = dayKind(atNormalizedIndex: normalizedIndex, input: input)
            switch kind {
            case .none:
                continue
            case .active:
                drafts.append(DoseEventDraft(pillProfileID: input.profileID, scheduledDate: day, scheduledTime: input.usualIntakeTime, status: .scheduled))
            case .placebo:
                drafts.append(DoseEventDraft(pillProfileID: input.profileID, scheduledDate: day, scheduledTime: input.usualIntakeTime, status: .placebo))
            }
        }
        return drafts
    }

    /// The next calendar day (strictly after `date`) that has no dose event at all —
    /// i.e. the start of a break/pause. Returns nil for schedules that never pause
    /// (28-pill, continuous) or a custom schedule with no "none" days.
    func nextBreakDate(input: PillScheduleInput, after date: Date) -> Date? {
        switch input.scheduleType {
        case .days28, .continuous, .days24Active4Placebo:
            return nil
        case .days21Active7Stop, .custom:
            break
        }
        let length = cycleLength(for: input)
        let startOfDate = calendar.startOfDay(for: date)
        for offset in 1...length {
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfDate) else { continue }
            let absoluteIndex = dayIndex(for: day, startDate: input.startDate)
            let normalizedIndex = ((absoluteIndex % length) + length) % length
            if dayKind(atNormalizedIndex: normalizedIndex, input: input) == .none {
                return day
            }
        }
        return nil
    }

    /// The next calendar day (strictly after `date`) that starts a new pack/cycle —
    /// used for schedules with no break (28-pill, continuous) where "next pause" doesn't apply.
    func nextPackStartDate(input: PillScheduleInput, after date: Date) -> Date {
        let length = cycleLength(for: input)
        let position = packPosition(for: date, input: input)
        let daysUntilNextPack = length - position.dayInPack + 1
        return calendar.date(byAdding: .day, value: daysUntilNextPack, to: calendar.startOfDay(for: date)) ?? date
    }

    private func dayKind(atNormalizedIndex normalizedIndex: Int, input: PillScheduleInput) -> DayKind {
        switch input.scheduleType {
        case .days21Active7Stop:
            return normalizedIndex < input.activePillCount ? .active : .none
        case .days24Active4Placebo:
            return normalizedIndex < input.activePillCount ? .active : .placebo
        case .days28:
            return .active
        case .continuous:
            return .active
        case .custom:
            guard let match = input.customDays.first(where: { $0.dayIndex == normalizedIndex }) else { return .none }
            if match.isPlaceboDay { return .placebo }
            return match.isActivePillDay ? .active : .none
        }
    }
}

/// Sendable draft produced by the pure calculator; converted into a real `DoseEvent`
/// (a SwiftData model) by `PillScheduleService`, which is MainActor-isolated.
struct DoseEventDraft: Sendable, Equatable {
    let pillProfileID: UUID
    let scheduledDate: Date
    let scheduledTime: Date
    let status: DoseStatus
}
