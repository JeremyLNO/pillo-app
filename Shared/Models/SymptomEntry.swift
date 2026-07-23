import Foundation
import SwiftData

@Model
final class SymptomEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var bleeding: Bool
    var spotting: Bool
    /// 0 (none) ... 10 (severe), optional.
    var painLevel: Int?
    var mood: String?
    var migraine: Bool
    var nausea: Bool
    var acne: Bool
    var libido: String?
    var customNotes: String?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        bleeding: Bool = false,
        spotting: Bool = false,
        painLevel: Int? = nil,
        mood: String? = nil,
        migraine: Bool = false,
        nausea: Bool = false,
        acne: Bool = false,
        libido: String? = nil,
        customNotes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.bleeding = bleeding
        self.spotting = spotting
        self.painLevel = painLevel
        self.mood = mood
        self.migraine = migraine
        self.nausea = nausea
        self.acne = acne
        self.libido = libido
        self.customNotes = customNotes
    }
}
