import XCTest
@testable import Pillo

@MainActor
final class AppLockServiceTests: XCTestCase {
    private var service: AppLockService!

    override func setUp() {
        super.setUp()
        service = AppLockService()
        service.removePIN() // clean slate — Keychain entries persist across test runs
    }

    override func tearDown() {
        service.removePIN()
        super.tearDown()
    }

    func testNoPINSetInitially() {
        XCTAssertFalse(service.isPINSet)
    }

    func testSetAndVerifyPIN() {
        service.setPIN("1234")
        XCTAssertTrue(service.isPINSet)
        XCTAssertTrue(service.verifyPIN("1234"))
        XCTAssertFalse(service.verifyPIN("0000"))
    }

    func testRemovePIN() {
        service.setPIN("4242")
        service.removePIN()
        XCTAssertFalse(service.isPINSet)
        XCTAssertFalse(service.verifyPIN("4242"))
    }

    func testChangingPINInvalidatesOldOne() {
        service.setPIN("1111")
        service.setPIN("2222")
        XCTAssertFalse(service.verifyPIN("1111"))
        XCTAssertTrue(service.verifyPIN("2222"))
    }
}
