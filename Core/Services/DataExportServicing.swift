import Foundation
import SwiftData

/// Full local-data export (spec section 20 "Exporter mes données" / section 23 data
/// policy). Always explicitly triggered by the user (Settings row), never automatic.
/// This is distinct from `HistoryExportServicing`, which produces a CSV *summary* of
/// dose history specifically for sharing with a clinician.
@MainActor
protocol DataExportServicing {
    /// Writes a JSON export of every locally-stored model to a temp file and returns
    /// its URL, ready for a `ShareLink`/share sheet.
    func exportAllData() throws -> URL
}

private struct ExportedProfile: Codable {
    let displayName: String
    let brandName: String?
    let pillType: String
    let activePillCount: Int
    let placeboPillCount: Int
    let cycleLength: Int
    let scheduleType: String
    let usualIntakeTime: Date
    let startDate: Date
    let allowedDelayMinutes: Int
    let continuousUse: Bool
    let isActive: Bool
}

private struct ExportedDoseEvent: Codable {
    let scheduledDate: Date
    let scheduledTime: Date
    let actualTakenDate: Date?
    let status: String
    let delayMinutes: Int
    let userNote: String?
}

private struct ExportedStockEntry: Codable {
    let remainingPacks: Int
    let pillsPerPack: Int
    let lowStockThreshold: Int
    let prescriptionExpirationDate: Date?
    let nextMedicalAppointment: Date?
}

private struct ExportedSymptomEntry: Codable {
    let date: Date
    let bleeding: Bool
    let spotting: Bool
    let painLevel: Int?
    let mood: String?
    let migraine: Bool
    let nausea: Bool
    let acne: Bool
    let libido: String?
    let customNotes: String?
}

private struct ExportedData: Codable {
    let exportedAt: Date
    let profiles: [ExportedProfile]
    let doseEvents: [ExportedDoseEvent]
    let stock: [ExportedStockEntry]
    let symptoms: [ExportedSymptomEntry]
}

final class DataExportService: DataExportServicing {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func exportAllData() throws -> URL {
        let profiles = try context.fetch(FetchDescriptor<PillProfile>()).map {
            ExportedProfile(
                displayName: $0.displayName, brandName: $0.brandName, pillType: $0.pillType.rawValue,
                activePillCount: $0.activePillCount, placeboPillCount: $0.placeboPillCount, cycleLength: $0.cycleLength,
                scheduleType: $0.scheduleType.rawValue, usualIntakeTime: $0.usualIntakeTime, startDate: $0.startDate,
                allowedDelayMinutes: $0.allowedDelayMinutes, continuousUse: $0.continuousUse, isActive: $0.isActive
            )
        }
        let events = try context.fetch(FetchDescriptor<DoseEvent>()).map {
            ExportedDoseEvent(
                scheduledDate: $0.scheduledDate, scheduledTime: $0.scheduledTime, actualTakenDate: $0.actualTakenDate,
                status: $0.status.rawValue, delayMinutes: $0.delayMinutes, userNote: $0.userNote
            )
        }
        let stock = try context.fetch(FetchDescriptor<StockEntry>()).map {
            ExportedStockEntry(
                remainingPacks: $0.remainingPacks, pillsPerPack: $0.pillsPerPack, lowStockThreshold: $0.lowStockThreshold,
                prescriptionExpirationDate: $0.prescriptionExpirationDate, nextMedicalAppointment: $0.nextMedicalAppointment
            )
        }
        let symptoms = try context.fetch(FetchDescriptor<SymptomEntry>()).map {
            ExportedSymptomEntry(
                date: $0.date, bleeding: $0.bleeding, spotting: $0.spotting, painLevel: $0.painLevel, mood: $0.mood,
                migraine: $0.migraine, nausea: $0.nausea, acne: $0.acne, libido: $0.libido, customNotes: $0.customNotes
            )
        }

        let export = ExportedData(exportedAt: .now, profiles: profiles, doseEvents: events, stock: stock, symptoms: symptoms)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(export)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pillo-export-\(Int(Date.now.timeIntervalSince1970)).json")
        try data.write(to: url, options: .atomic)
        return url
    }
}
