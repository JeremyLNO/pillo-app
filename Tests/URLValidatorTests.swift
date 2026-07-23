import XCTest
@testable import Pillo

final class URLValidatorTests: XCTestCase {
    func testPilloSchemeIsAllowed() {
        XCTAssertTrue(URLValidator.isAllowed(URL(string: "pillo://home")!))
        XCTAssertTrue(URLValidator.isAllowed(URL(string: "pillo://pill/missed")!))
    }

    func testAllowedHTTPSHostsAccepted() {
        XCTAssertTrue(URLValidator.isAllowed(URL(string: "https://crazybeelabs.com/support/")!))
        XCTAssertTrue(URLValidator.isAllowed(URL(string: "https://www.crazybeelabs.com/")!))
        XCTAssertTrue(URLValidator.isAllowed(URL(string: "https://apps.apple.com/app/id123")!))
    }

    func testDisallowedSchemesRejected() {
        XCTAssertFalse(URLValidator.isAllowed(URL(string: "http://crazybeelabs.com/")!)) // not https
        XCTAssertFalse(URLValidator.isAllowed(URL(string: "javascript://alert(1)")!))
        XCTAssertFalse(URLValidator.isAllowed(URL(string: "file:///etc/passwd")!))
    }

    func testDisallowedHostsRejected() {
        XCTAssertFalse(URLValidator.isAllowed(URL(string: "https://evil.com/")!))
        XCTAssertFalse(URLValidator.isAllowed(URL(string: "https://crazybeelabs.com.evil.com/")!))
    }

    func testValidatedParsesAndValidatesInOneStep() {
        XCTAssertNotNil(URLValidator.validated("pillo://settings"))
        XCTAssertNil(URLValidator.validated("https://evil.com/"))
        XCTAssertNil(URLValidator.validated(nil))
        XCTAssertNil(URLValidator.validated("not a url"))
    }
}
