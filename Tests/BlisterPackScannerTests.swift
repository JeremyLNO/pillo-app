import XCTest
@testable import Pillo

final class BlisterPackScannerTests: XCTestCase {
    func testDetects21Active7Stop() {
        let result = BlisterPackScanner.matchSchedule(recognizedStrings: ["21 comprimés actifs", "7 comprimés placebo"])
        XCTAssertEqual(result, .init(scheduleType: .days21Active7Stop, activePillCount: 21, placeboPillCount: 7))
    }

    func testDetects24Active4Placebo() {
        let result = BlisterPackScanner.matchSchedule(recognizedStrings: ["24 jours", "4 jours de pause"])
        XCTAssertEqual(result, .init(scheduleType: .days24Active4Placebo, activePillCount: 24, placeboPillCount: 4))
    }

    func testDetects28() {
        let result = BlisterPackScanner.matchSchedule(recognizedStrings: ["28 comprimés", "Prendre tous les jours"])
        XCTAssertEqual(result, .init(scheduleType: .days28, activePillCount: 28, placeboPillCount: 0))
    }

    func testInconclusiveText_returnsNil() {
        let result = BlisterPackScanner.matchSchedule(recognizedStrings: ["Prendre à heure fixe", "Consulter la notice"])
        XCTAssertNil(result)
    }

    func testNumbersEmbeddedInWords_areStillExtracted() {
        let result = BlisterPackScanner.matchSchedule(recognizedStrings: ["Plaquette24/4"])
        XCTAssertEqual(result, .init(scheduleType: .days24Active4Placebo, activePillCount: 24, placeboPillCount: 4))
    }
}
