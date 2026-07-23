import Foundation
import SwiftData

@Model
final class DoseEvent: Identifiable {
    @Attribute(.unique) var id: UUID
    var pillProfileID: UUID
    var scheduledDate: Date
    var scheduledTime: Date
    var actualTakenDate: Date?
    var statusRaw: String
    var delayMinutes: Int
    var userNote: String?
    var createdAt: Date
    var updatedAt: Date

    var status: DoseStatus {
        get { DoseStatus(rawValue: statusRaw) ?? .unknown }
        set { statusRaw = newValue.rawValue }
    }

    /// The full scheduled instant, combining `scheduledDate`'s calendar day with `scheduledTime`'s time-of-day.
    var scheduledDateTime: Date {
        let calendar = Calendar.current
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: scheduledDate)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: scheduledTime)
        var merged = DateComponents()
        merged.year = dayComponents.year
        merged.month = dayComponents.month
        merged.day = dayComponents.day
        merged.hour = timeComponents.hour
        merged.minute = timeComponents.minute
        merged.second = timeComponents.second
        return calendar.date(from: merged) ?? scheduledDate
    }

    init(
        id: UUID = UUID(),
        pillProfileID: UUID,
        scheduledDate: Date,
        scheduledTime: Date,
        actualTakenDate: Date? = nil,
        status: DoseStatus = .scheduled,
        delayMinutes: Int = 0,
        userNote: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.pillProfileID = pillProfileID
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.actualTakenDate = actualTakenDate
        self.statusRaw = status.rawValue
        self.delayMinutes = delayMinutes
        self.userNote = userNote
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
