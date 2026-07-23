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
