import XCTest
@testable import Pillo

final class SemanticVersionTests: XCTestCase {
    func testBasicOrdering() {
        XCTAssertLessThan(SemanticVersion("1.0.0")!, SemanticVersion("1.0.1")!)
        XCTAssertLessThan(SemanticVersion("1.0.0")!, SemanticVersion("1.1.0")!)
        XCTAssertLessThan(SemanticVersion("1.9.9")!, SemanticVersion("2.0.0")!)
        XCTAssertGreaterThan(SemanticVersion("2.0.0")!, SemanticVersion("1.9.9")!)
    }

    func testEquality() {
        XCTAssertEqual(SemanticVersion("1.4.0")!, SemanticVersion("1.4.0")!)
        XCTAssertEqual(SemanticVersion("1.4")!, SemanticVersion("1.4.0")!) // missing components treated as 0
    }

    func testUnevenComponentCounts() {
        XCTAssertLessThan(SemanticVersion("1.0")!, SemanticVersion("1.0.1")!)
        XCTAssertEqual(SemanticVersion("2")!, SemanticVersion("2.0.0")!)
    }

    func testPreReleaseSuffixIsTolerated() {
        // Only the leading digits of each component are read; "-beta1" is ignored
        // rather than causing the whole version string to fail to parse.
        XCTAssertEqual(SemanticVersion("1.4.0-beta1")!, SemanticVersion("1.4.0")!)
    }

    func testInvalidStringsReturnNil() {
        XCTAssertNil(SemanticVersion(""))
        XCTAssertNil(SemanticVersion("abc"))
    }
}
