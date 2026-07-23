import AppIntents
import SwiftData
import Foundation

/// Runs entirely inside the widget extension process — opens the same App-Group-shared
/// SwiftData store the phone app uses (`PersistenceController.make()`), confirms the
/// dose via the same `DoseTrackingService` the app itself uses (no duplicated logic),
/// then writes an optimistic patch to the cached `WidgetSnapshot` so the widget reflects
/// the change instantly. The phone app recomputes a fully accurate snapshot (advancing to
/// the real next dose, exact streak) the next time it's foregrounded — see
/// `Core/Services/WidgetBridge.swift`.
struct MarkDoseTakenIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark dose as taken"
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Dose Event ID")
    var doseEventIDString: String

    @Parameter(title: "Profile ID")
    var profileIDString: String

    init() {}

    init(doseEventID: UUID, profileID: UUID) {
        self.doseEventIDString = doseEventID.uuidString
        self.profileIDString = profileID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let doseEventID = UUID(uuidString: doseEventIDString),
              let profileID = UUID(uuidString: profileIDString)
        else {
            return .result()
        }

        let context = PersistenceController.make().mainContext
        guard let event = try? context.fetch(FetchDescriptor<DoseEvent>(predicate: #Predicate { $0.id == doseEventID })).first,
              let profile = try? context.fetch(FetchDescriptor<PillProfile>(predicate: #Predicate { $0.id == profileID })).first
        else {
            return .result()
        }

        let service = DoseTrackingService(context: context, notificationService: nil)
        try? service.confirmDose(event, profile: profile, takenAt: .now)

        patchSnapshot(confirmedEventID: doseEventID)
        return .result()
    }

    private func patchSnapshot(confirmedEventID: UUID) {
        let current = WidgetSnapshotStore.read()
        guard current.nextDoseEventID == confirmedEventID else { return }

        let patchedCells = current.blisterCells.map { cell in
            cell.dayNumber == current.dayInPack
                ? WidgetSnapshot.BlisterCell(dayNumber: cell.dayNumber, statusRaw: BlisterCellState.taken.rawValue)
                : cell
        }
        let patched = WidgetSnapshot(
            generatedAt: .now,
            hasActiveProfile: current.hasActiveProfile,
            discreetMode: current.discreetMode,
            nextDoseEventID: current.nextDoseEventID,
            nextProfileID: current.nextProfileID,
            nextDoseDate: current.nextDoseDate,
            nextDoseIsConfirmed: true,
            dayInPack: current.dayInPack,
            packSize: current.packSize,
            blisterCells: patchedCells,
            streakDays: current.streakDays + 1,
            observancePercent: current.observancePercent
        )
        WidgetSnapshotStore.write(patched)
    }
}
