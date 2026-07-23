import Foundation
import SwiftData

/// Kept dependency-free of anything app-only (no `PillScheduleCalculator`, no demo-data
/// seeding — see `Core/Persistence/PersistenceController+Preview.swift` for that) so this
/// file can compile into the iOS widget extension too. The widget's "mark dose as taken"
/// AppIntent opens the exact same on-disk store via `make()`, not a copy.
enum PersistenceController {
    static let schema = Schema([
        PillProfile.self,
        DoseEvent.self,
        NotificationPreferences.self,
        StockEntry.self,
        SymptomEntry.self,
        UserPreferences.self,
        CustomScheduleDay.self,
    ])

    /// Tries the shared App Group store first (so the iOS widget extension's "mark as
    /// taken" intent reads/writes the exact same database the app uses); falls back to
    /// in-memory only if disk storage genuinely fails to initialize, so neither the app
    /// nor the widget ever hard-crashes on a corrupt store.
    ///
    /// `fresh: true` (driven by the `-freshInstall` launch argument) points at a brand
    /// new on-disk file under `/tmp` instead of the shared store — used by UI tests that
    /// need to exercise onboarding-from-scratch without touching, or being polluted by,
    /// real local data.
    static func make(fresh: Bool = false) -> ModelContainer {
        if fresh {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("pillo-fresh-\(UUID().uuidString).sqlite")
            let config = ModelConfiguration(schema: schema, url: url)
            if let container = try? ModelContainer(for: schema, configurations: [config]) {
                return container
            }
        }
        let groupStore = ModelConfiguration(schema: schema, groupContainer: .identifier(AppGroup.identifier))
        if let container = try? ModelContainer(for: schema, configurations: [groupStore]) {
            return container
        }
        // No App Group entitlement (e.g. a target that forgot to add it) — fall back to
        // the sandbox-local store rather than refusing to launch.
        let onDisk = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let container = try? ModelContainer(for: schema, configurations: [onDisk]) {
            return container
        }
        let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        guard let fallback = try? ModelContainer(for: schema, configurations: [inMemory]) else {
            fatalError("Unable to create even an in-memory ModelContainer for Pillo.")
        }
        return fallback
    }

    @MainActor
    static func inMemory() -> ModelContainer {
        let inMemory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [inMemory])
    }
}
