import Foundation

/// Precomputed, display-ready data for the iOS widgets — deliberately doesn't ask the
/// widget process to re-run `PillScheduleCalculator` or query SwiftData on every
/// timeline refresh. The phone app computes this once (in `WidgetBridge`, called from
/// every `DoseTrackingService` mutation and on relevant app-lifecycle events) and writes
/// it to the App Group; the widget extension's `TimelineProvider` just reads it back.
///
/// The one exception is the "mark as taken" AppIntent, which does open the real shared
/// SwiftData store (see `PersistenceController.make()`) to perform the actual write —
/// this struct is a read path only.
struct WidgetSnapshot: Codable, Sendable, Equatable {
    struct BlisterCell: Codable, Sendable, Equatable {
        let dayNumber: Int
        /// Raw `DoseStatus` value, or "pause" for a day with no scheduled dose.
        let statusRaw: String
    }

    let generatedAt: Date
    let hasActiveProfile: Bool
    let discreetMode: Bool

    let nextDoseEventID: UUID?
    let nextProfileID: UUID?
    let nextDoseDate: Date?
    let nextDoseIsConfirmed: Bool

    let dayInPack: Int
    let packSize: Int
    let blisterCells: [BlisterCell]

    let streakDays: Int
    let observancePercent: Int

    static let empty = WidgetSnapshot(
        generatedAt: .distantPast,
        hasActiveProfile: false,
        discreetMode: false,
        nextDoseEventID: nil,
        nextProfileID: nil,
        nextDoseDate: nil,
        nextDoseIsConfirmed: false,
        dayInPack: 0,
        packSize: 28,
        blisterCells: [],
        streakDays: 0,
        observancePercent: 0
    )

    /// Plausible-looking example data for WidgetKit's placeholder/redacted rendering —
    /// never real data, just needs the right shape.
    static let placeholder = WidgetSnapshot(
        generatedAt: .now,
        hasActiveProfile: true,
        discreetMode: false,
        nextDoseEventID: UUID(),
        nextProfileID: UUID(),
        nextDoseDate: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: .now),
        nextDoseIsConfirmed: false,
        dayInPack: 12,
        packSize: 28,
        blisterCells: (1...28).map { day in
            BlisterCell(dayNumber: day, statusRaw: day < 12 ? "takenOnTime" : (day == 12 ? "scheduled" : "scheduled"))
        },
        streakDays: 11,
        observancePercent: 97
    )
}
