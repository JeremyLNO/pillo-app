import Foundation
import WidgetKit

/// Read/write access to the cached `WidgetSnapshot` in the App Group container. `write`
/// also triggers a WidgetKit timeline reload — callers never need to remember to do that
/// separately. Safe to import from both the app (writes after every dose mutation) and
/// the widget extension (reads in the `TimelineProvider`; the "mark as taken" AppIntent
/// also writes an optimistic patch — see `PilloWidgetsExtension/MarkDoseTakenIntent.swift`).
enum WidgetSnapshotStore {
    private static let key = "widgetSnapshot.v1"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroup.identifier)
    }

    static func read() -> WidgetSnapshot {
        guard let data = defaults?.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }

    static func write(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults?.set(data, forKey: key)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
