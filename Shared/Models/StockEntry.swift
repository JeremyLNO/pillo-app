import Foundation
import SwiftData

@Model
final class StockEntry {
    @Attribute(.unique) var id: UUID
    var remainingPacks: Int
    var pillsPerPack: Int
    var lowStockThreshold: Int
    var prescriptionExpirationDate: Date?
    var nextMedicalAppointment: Date?
    var lastUpdatedAt: Date
    var renewalReminderEnabled: Bool

    init(
        id: UUID = UUID(),
        remainingPacks: Int = 1,
        pillsPerPack: Int = 28,
        lowStockThreshold: Int = 1,
        prescriptionExpirationDate: Date? = nil,
        nextMedicalAppointment: Date? = nil,
        lastUpdatedAt: Date = .now,
        renewalReminderEnabled: Bool = true
    ) {
        self.id = id
        self.remainingPacks = remainingPacks
        self.pillsPerPack = pillsPerPack
        self.lowStockThreshold = lowStockThreshold
        self.prescriptionExpirationDate = prescriptionExpirationDate
        self.nextMedicalAppointment = nextMedicalAppointment
        self.lastUpdatedAt = lastUpdatedAt
        self.renewalReminderEnabled = renewalReminderEnabled
    }
}
