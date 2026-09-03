import Foundation
import SwiftData

/// App-only (not shared into the widget/watch targets) since it depends on
/// `PillScheduleCalculator`. Demo data is entirely synthetic/non-medical — see README
/// "Demo data".
extension PersistenceController {
    @MainActor
    static func preview() -> ModelContainer {
        let container = inMemory()
        seedPreviewData(into: container.mainContext)
        return container
    }

    /// Store-listing screenshots only (`-screenshotSeed`). Same synthetic, non-medical
    /// data as `preview()`, but with three weeks of history already confirmed so the
    /// Tracking tab shows a real streak and adherence figure instead of zeros. Kept apart
    /// from `seedPreviewData` on purpose: the UI tests assert against that fixture.
    @MainActor
    static func screenshotPreview() -> ModelContainer {
        let container = inMemory()
        let context = container.mainContext
        seedPreviewData(into: context)

        let calendar = Calendar.current
        guard let profile = try? context.fetch(FetchDescriptor<PillProfile>()).first,
              let events = try? context.fetch(FetchDescriptor<DoseEvent>())
        else { return container }

        // Confirm every past dose, all but one comfortably on time.
        let startOfToday = calendar.startOfDay(for: .now)
        for event in events where event.scheduledDate < startOfToday {
            let daysAgo = calendar.dateComponents([.day], from: event.scheduledDate, to: startOfToday).day ?? 0
            let delayMinutes = daysAgo == 4 ? 95 : Int.random(in: 0...6)
            event.actualTakenDate = event.scheduledDateTime.addingTimeInterval(TimeInterval(delayMinutes * 60))
            event.delayMinutes = delayMinutes
            if event.status != .placebo {
                event.status = delayMinutes <= profile.allowedDelayMinutes ? .takenOnTime : .takenLate
            }
        }

        if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: .now) {
            context.insert(SymptomEntry(date: twoDaysAgo, painLevel: 2, migraine: true))
        }
        if let sixDaysAgo = calendar.date(byAdding: .day, value: -6, to: .now) {
            context.insert(SymptomEntry(date: sixDaysAgo, spotting: true, nausea: true))
        }

        try? context.save()
        return container
    }

    @MainActor
    static func seedPreviewData(into context: ModelContext) {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -11, to: .now) ?? .now
        let intakeTime = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: .now) ?? .now

        let profile = PillProfile(
            displayName: "Ma pilule",
            brandName: nil,
            pillType: .combined,
            activePillCount: 21,
            placeboPillCount: 7,
            cycleLength: 28,
            scheduleType: .days21Active7Stop,
            usualIntakeTime: intakeTime,
            startDate: startDate
        )
        context.insert(profile)

        let calculator = PillScheduleCalculator()
        let scheduleInput = PillScheduleInput(
            profileID: profile.id,
            scheduleType: profile.scheduleType,
            startDate: profile.startDate,
            activePillCount: profile.activePillCount,
            placeboPillCount: profile.placeboPillCount,
            usualIntakeTime: profile.usualIntakeTime
        )
        let drafts = calculator.generateDrafts(input: scheduleInput, from: startDate, cyclesToGenerate: 1)
        for draft in drafts {
            context.insert(DoseEvent(pillProfileID: draft.pillProfileID, scheduledDate: draft.scheduledDate, scheduledTime: draft.scheduledTime, status: draft.status))
        }

        context.insert(NotificationPreferences())
        context.insert(StockEntry(remainingPacks: 2))
        let prefs = UserPreferences()
        prefs.completedOnboarding = true
        prefs.hasSeenCommitmentScreen = true
        context.insert(prefs)
    }
}
