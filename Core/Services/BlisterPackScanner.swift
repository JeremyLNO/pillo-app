import Foundation
import Vision
import CoreGraphics

/// Best-effort onboarding assist: reads printed numbers off a photographed blister pack
/// (e.g. "21", "7", "24", "4", "28") via on-device text recognition and suggests a
/// matching `ScheduleType` + pill counts. Never authoritative — the onboarding step stays
/// fully editable afterward, and an inconclusive scan just leaves the manual defaults
/// untouched. This only guesses a packaging count, not medical content, so it doesn't run
/// into the app-wide "no LLM-generated medical content" rule.
enum BlisterPackScanner {
    struct ScanResult: Equatable {
        var scheduleType: ScheduleType
        var activePillCount: Int
        var placeboPillCount: Int
    }

    static func scan(_ image: CGImage) async -> ScanResult? {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        guard (try? handler.perform([request])) != nil else { return nil }
        let strings = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        return matchSchedule(recognizedStrings: strings)
    }

    /// Pure and unit-testable: given the raw text lines Vision recognized anywhere on the
    /// packaging, look for the pill-count numbers that disambiguate the 3 fixed schedule
    /// shapes. `.continuous` and `.custom` aren't guessable from packaging text alone, so
    /// this only ever returns one of the 3 fixed-count types.
    static func matchSchedule(recognizedStrings: [String]) -> ScanResult? {
        let numbers = Set(recognizedStrings.flatMap { line in
            line.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        })

        if numbers.contains(28) {
            return ScanResult(scheduleType: .days28, activePillCount: 28, placeboPillCount: 0)
        }
        if numbers.contains(24), numbers.contains(4) {
            return ScanResult(scheduleType: .days24Active4Placebo, activePillCount: 24, placeboPillCount: 4)
        }
        if numbers.contains(21) {
            return ScanResult(scheduleType: .days21Active7Stop, activePillCount: 21, placeboPillCount: 7)
        }
        return nil
    }
}
