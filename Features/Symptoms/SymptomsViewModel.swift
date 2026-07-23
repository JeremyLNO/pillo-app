import Foundation
import Observation

@Observable
@MainActor
final class SymptomsViewModel {
    var bleeding = false
    var spotting = false
    var painLevel: Double = 0
    var trackPain = false
    var mood: String = ""
    var migraine = false
    var nausea = false
    var acne = false
    var libido: String = ""
    var customNotes: String = ""

    func reset() {
        bleeding = false
        spotting = false
        painLevel = 0
        trackPain = false
        mood = ""
        migraine = false
        nausea = false
        acne = false
        libido = ""
        customNotes = ""
    }

    func makeEntry(date: Date = .now) -> SymptomEntry {
        SymptomEntry(
            date: date,
            bleeding: bleeding,
            spotting: spotting,
            painLevel: trackPain ? Int(painLevel) : nil,
            mood: mood.isEmpty ? nil : mood,
            migraine: migraine,
            nausea: nausea,
            acne: acne,
            libido: libido.isEmpty ? nil : libido,
            customNotes: customNotes.isEmpty ? nil : customNotes
        )
    }
}
