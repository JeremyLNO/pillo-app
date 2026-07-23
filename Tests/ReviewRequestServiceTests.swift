import XCTest
@testable import Pillo

@MainActor
final class ReviewRequestServiceTests: XCTestCase {
    func testDoesNotRequestBeforeMinimumInterval() {
        let service = ReviewRequestService(minimumInterval: 24 * 60 * 60)
        let preferences = UserPreferences(installDate: .now)
        XCTAssertFalse(service.shouldRequestReview(preferences: preferences))
    }

    func testRequestsAfterMinimumInterval() {
        let service = ReviewRequestService(minimumInterval: 24 * 60 * 60)
        let preferences = UserPreferences(installDate: .now.addingTimeInterval(-25 * 60 * 60))
        XCTAssertTrue(service.shouldRequestReview(preferences: preferences))
    }

    func testNeverRequestsTwice() {
        let service = ReviewRequestService(minimumInterval: 24 * 60 * 60)
        let preferences = UserPreferences(installDate: .now.addingTimeInterval(-48 * 60 * 60))
        XCTAssertTrue(service.shouldRequestReview(preferences: preferences))
        service.markRequested(preferences: preferences)
        XCTAssertFalse(service.shouldRequestReview(preferences: preferences))
        XCTAssertNotNil(preferences.reviewRequestDate)
    }
}
