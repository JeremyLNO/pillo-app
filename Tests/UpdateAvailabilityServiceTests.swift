import XCTest
@testable import Pillo

final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responseData: Data?
    nonisolated(unsafe) static var statusCode: Int = 200

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.statusCode, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if let data = Self.responseData {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@MainActor
final class UpdateAvailabilityServiceTests: XCTestCase {
    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    func testNoUpdateWhenRunningVersionIsCurrent() async {
        StubURLProtocol.responseData = """
        {"latestVersion":"1.0.0","minimumSupportedVersion":"1.0.0","appStoreURL":"https://apps.apple.com/app/id123","message":{"en":"Update available"}}
        """.data(using: .utf8)
        let service = UpdateAvailabilityService(
            remoteConfigURL: URL(string: "https://crazybeelabs.com/pillo-config.json"),
            currentVersion: "1.0.0",
            currentLanguage: { .en },
            urlSession: makeSession()
        )
        let result = await service.checkForUpdate()
        XCTAssertNil(result)
    }

    func testOptionalUpdateWhenBelowLatestButAboveMinimum() async {
        StubURLProtocol.responseData = """
        {"latestVersion":"1.4.0","minimumSupportedVersion":"1.0.0","appStoreURL":"https://apps.apple.com/app/id123","message":{"en":"Update available","fr":"Mise a jour disponible"}}
        """.data(using: .utf8)
        let service = UpdateAvailabilityService(
            remoteConfigURL: URL(string: "https://crazybeelabs.com/pillo-config.json"),
            currentVersion: "1.2.0",
            currentLanguage: { .fr },
            urlSession: makeSession()
        )
        let result = await service.checkForUpdate()
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.isMandatory)
        XCTAssertEqual(result!.message, "Mise a jour disponible")
    }

    func testMandatoryUpdateWhenBelowMinimumSupported() async {
        StubURLProtocol.responseData = """
        {"latestVersion":"2.0.0","minimumSupportedVersion":"1.5.0","appStoreURL":"https://apps.apple.com/app/id123","message":{"en":"Critical update"}}
        """.data(using: .utf8)
        let service = UpdateAvailabilityService(
            remoteConfigURL: URL(string: "https://crazybeelabs.com/pillo-config.json"),
            currentVersion: "1.0.0",
            currentLanguage: { .en },
            urlSession: makeSession()
        )
        let result = await service.checkForUpdate()
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.isMandatory)
    }

    func testNoConfiguredURLReturnsNil() async {
        let service = UpdateAvailabilityService(remoteConfigURL: nil, currentVersion: "1.0.0", currentLanguage: { .en }, urlSession: makeSession())
        let result = await service.checkForUpdate()
        XCTAssertNil(result)
    }

    func testUnvalidatedAppStoreURLIsRejected() async {
        StubURLProtocol.responseData = """
        {"latestVersion":"9.9.9","minimumSupportedVersion":"1.0.0","appStoreURL":"https://evil.com/fake","message":{"en":"Update"}}
        """.data(using: .utf8)
        let service = UpdateAvailabilityService(
            remoteConfigURL: URL(string: "https://crazybeelabs.com/pillo-config.json"),
            currentVersion: "1.0.0",
            currentLanguage: { .en },
            urlSession: makeSession()
        )
        let result = await service.checkForUpdate()
        XCTAssertNil(result, "An untrusted appStoreURL host must be rejected, never surfaced as a valid update")
    }
}
