import AppIntents
import SwiftData
import Foundation

/// Lets Siri/Shortcuts confirm the next dose without opening the app ("Dis Siri, j'ai pris
/// ma pilule"). Mirrors the interactive widget's `MarkDoseTakenIntent`
/// (PilloWidgets/MarkDoseTakenIntent.swift) — same store, same `DoseTrackingService`, no
/// duplicated business logic — but runs in the main app process, so unlike the widget
/// intent it can use `PillScheduleService` directly to find the dose itself instead of
/// being handed IDs.
struct ConfirmTodayDoseIntent: AppIntent {
    static let title: LocalizedStringResource = "intent.confirmDose.title"
    static let description = IntentDescription("intent.confirmDose.description")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = PersistenceController.make().mainContext

        guard let profile = try? context.fetch(FetchDescriptor<PillProfile>(predicate: #Predicate { $0.isActive })).first else {
            return .result(dialog: IntentDialog("intent.confirmDose.noProfile"))
        }

        let scheduleService = PillScheduleService(context: context)
        guard let event = try? scheduleService.nextDose(for: profile, after: .now), event.actualTakenDate == nil else {
            return .result(dialog: IntentDialog("intent.confirmDose.alreadyDoneOrNone"))
        }

        let trackingService = DoseTrackingService(context: context, notificationService: nil)
        try? trackingService.confirmDose(event, profile: profile, takenAt: .now)

        return .result(dialog: IntentDialog("intent.confirmDose.success"))
    }
}
