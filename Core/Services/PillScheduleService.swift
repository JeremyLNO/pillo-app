import Foundation
import SwiftData

@MainActor
final class PillScheduleService: PillScheduleServicing {
    private let context: ModelContext
    private let calculator: PillScheduleCalculator

    init(context: ModelContext, calculator: PillScheduleCalculator = PillScheduleCalculator()) {
        self.context = context
        self.calculator = calculator
    }

    private func input(for profile: PillProfile) -> PillScheduleInput {
        let customDays: [CustomDayInput]
        if profile.scheduleType == .custom {
            let profileID = profile.id
            let descriptor = FetchDescriptor<CustomScheduleDay>(
                predicate: #Predicate { $0.pillProfileID == profileID }
            )
            let stored = (try? context.fetch(descriptor)) ?? []
            customDays = stored.map { CustomDayInput(dayIndex: $0.dayIndex, isActivePillDay: $0.isActivePillDay, isPlaceboDay: $0.isPlaceboDay) }
        } else {
            customDays = []
        }
        return PillScheduleInput(
            profileID: profile.id,
            scheduleType: profile.scheduleType,
            startDate: profile.startDate,
            activePillCount: profile.activePillCount,
            placeboPillCount: profile.placeboPillCount,
            usualIntakeTime: profile.usualIntakeTime,
            customDays: customDays
        )
    }

    @discardableResult
    func ensureDoseEvents(for profile: PillProfile, from date: Date, cyclesToGenerate: Int) throws -> [DoseEvent] {
        let scheduleInput = input(for: profile)
        let drafts = calculator.generateDrafts(input: scheduleInput, from: date, cyclesToGenerate: cyclesToGenerate)

        let profileID = profile.id
        let descriptor = FetchDescriptor<DoseEvent>(predicate: #Predicate { $0.pillProfileID == profileID })
        let existing = try context.fetch(descriptor)
        let calendar = Calendar.current
        var existingByDay = Set(existing.map { calendar.startOfDay(for: $0.scheduledDate) })

        var inserted: [DoseEvent] = []
        for draft in drafts {
            let day = calendar.startOfDay(for: draft.scheduledDate)
            guard !existingByDay.contains(day) else { continue }
            let event = DoseEvent(
                pillProfileID: draft.pillProfileID,
                scheduledDate: day,
                scheduledTime: draft.scheduledTime,
                status: draft.status
            )
            context.insert(event)
            inserted.append(event)
            existingByDay.insert(day)
        }
        if !inserted.isEmpty {
            try context.save()
        }
        return inserted
    }

    func nextDose(for profile: PillProfile, after date: Date) throws -> DoseEvent? {
        try ensureDoseEvents(for: profile, from: date, cyclesToGenerate: 1)
        let events = try doseEvents(for: profile)
        return events
            .filter { $0.status == .scheduled || $0.status == .unknown || $0.status == .placebo }
            .filter { $0.scheduledDateTime >= Calendar.current.startOfDay(for: date) }
            .sorted { $0.scheduledDateTime < $1.scheduledDateTime }
            .first
    }

    func packPosition(for date: Date, profile: PillProfile) -> PackPosition {
        calculator.packPosition(for: date, input: input(for: profile))
    }

    func doseEvents(for profile: PillProfile) throws -> [DoseEvent] {
        let profileID = profile.id
        var descriptor = FetchDescriptor<DoseEvent>(predicate: #Predicate { $0.pillProfileID == profileID })
        descriptor.sortBy = [SortDescriptor(\.scheduledDate, order: .forward)]
        return try context.fetch(descriptor)
    }

    func nextBreakDate(for profile: PillProfile, after date: Date) -> Date? {
        calculator.nextBreakDate(input: input(for: profile), after: date)
    }

    func nextPackStartDate(for profile: PillProfile, after date: Date) -> Date {
        calculator.nextPackStartDate(input: input(for: profile), after: date)
    }
}
