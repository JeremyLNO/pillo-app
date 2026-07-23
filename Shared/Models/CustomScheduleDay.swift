import Foundation
import SwiftData

/// Additive model beyond the spec's literal field list — required to make
/// `ScheduleType.custom` generable: a fully custom plan has no formula, only
/// an explicit per-day pattern.
@Model
final class CustomScheduleDay {
    @Attribute(.unique) var id: UUID
    var pillProfileID: UUID
    /// 0-based offset within the custom cycle.
    var dayIndex: Int
    var isActivePillDay: Bool
    var isPlaceboDay: Bool

    init(
        id: UUID = UUID(),
        pillProfileID: UUID,
        dayIndex: Int,
        isActivePillDay: Bool,
        isPlaceboDay: Bool = false
    ) {
        self.id = id
        self.pillProfileID = pillProfileID
        self.dayIndex = dayIndex
        self.isActivePillDay = isActivePillDay
        self.isPlaceboDay = isPlaceboDay
    }
}
