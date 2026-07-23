import Foundation
import SwiftData

@Model
final class PillProfile {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var brandName: String?
    var pillTypeRaw: String
    var activePillCount: Int
    var placeboPillCount: Int
    var cycleLength: Int
    var scheduleTypeRaw: String
    var usualIntakeTime: Date
    var startDate: Date
    var allowedDelayMinutes: Int
    var continuousUse: Bool
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    var pillType: PillType {
        get { PillType(rawValue: pillTypeRaw) ?? .combined }
        set { pillTypeRaw = newValue.rawValue }
    }

    var scheduleType: ScheduleType {
        get { ScheduleType(rawValue: scheduleTypeRaw) ?? .days28 }
        set { scheduleTypeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        displayName: String,
        brandName: String? = nil,
        pillType: PillType = .combined,
        activePillCount: Int = 21,
        placeboPillCount: Int = 7,
        cycleLength: Int = 28,
        scheduleType: ScheduleType = .days21Active7Stop,
        usualIntakeTime: Date,
        startDate: Date,
        allowedDelayMinutes: Int = 720,
        continuousUse: Bool = false,
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.brandName = brandName
        self.pillTypeRaw = pillType.rawValue
        self.activePillCount = activePillCount
        self.placeboPillCount = placeboPillCount
        self.cycleLength = cycleLength
        self.scheduleTypeRaw = scheduleType.rawValue
        self.usualIntakeTime = usualIntakeTime
        self.startDate = startDate
        self.allowedDelayMinutes = allowedDelayMinutes
        self.continuousUse = continuousUse
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
