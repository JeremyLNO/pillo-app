import Foundation
import Observation

@Observable
@MainActor
final class BlisterPackViewModel {
    var correctingEvent: DoseEvent?

    func beginCorrection(_ event: DoseEvent) {
        correctingEvent = event
    }

    func applyCorrection(takenAt: Date?, note: String?, profile: PillProfile, services: ServiceContainer) {
        guard let event = correctingEvent else { return }
        try? services.doseTracking.correctDose(event, profile: profile, takenAt: takenAt, note: note)
        correctingEvent = nil
    }

    func cancelCorrection() {
        correctingEvent = nil
    }
}
