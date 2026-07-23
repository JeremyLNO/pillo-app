import XCTest
import SwiftData
@testable import Pillo

@MainActor
final class DoseTrackingServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var service: DoseTrackingService!
    private var profile: PillProfile!

    override func setUp() {
        super.setUp()
        let schema = Schema([PillProfile.self, DoseEvent.self])
        // Must be retained as an instance property — a ModelContainer held only as a local
        // `setUp()` variable can be deallocated before the test body runs, invalidating
        // every model instance obtained from its context ("destroyed by ModelContext.reset").
        container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        context = container.mainContext
        service = DoseTrackingService(context: context, notificationService: nil)

        profile = PillProfile(
            displayName: "Test",
            usualIntakeTime: .now,
            startDate: .now,
            allowedDelayMinutes: 60
        )
        context.insert(profile)
    }

    private func makeEvent(status: DoseStatus = .scheduled) -> DoseEvent {
        let event = DoseEvent(pillProfileID: profile.id, scheduledDate: .now, scheduledTime: .now, status: status)
        context.insert(event)
        return event
    }

    func testConfirmDose_withinAllowedDelay_isOnTime() throws {
        let event = makeEvent()
        let takenAt = event.scheduledDateTime.addingTimeInterval(10 * 60)
        try service.confirmDose(event, profile: profile, takenAt: takenAt)
        XCTAssertEqual(event.status, .takenOnTime)
        XCTAssertEqual(event.delayMinutes, 10)
        XCTAssertNotNil(event.actualTakenDate)
    }

    func testConfirmDose_beyondAllowedDelay_isLate() throws {
        let event = makeEvent()
        let takenAt = event.scheduledDateTime.addingTimeInterval(90 * 60)
        try service.confirmDose(event, profile: profile, takenAt: takenAt)
        XCTAssertEqual(event.status, .takenLate)
        XCTAssertEqual(event.delayMinutes, 90)
    }

    func testConfirmDose_placeboKeepsPlaceboStatus() throws {
        let event = makeEvent(status: .placebo)
        try service.confirmDose(event, profile: profile, takenAt: .now)
        XCTAssertEqual(event.status, .placebo)
        XCTAssertNotNil(event.actualTakenDate)
    }

    func testUndoConfirmation_revertsToScheduled() throws {
        let event = makeEvent()
        try service.confirmDose(event, profile: profile, takenAt: .now)
        try service.undoConfirmation(event)
        XCTAssertEqual(event.status, .scheduled)
        XCTAssertNil(event.actualTakenDate)
        XCTAssertEqual(event.delayMinutes, 0)
    }

    func testMarkMissed_setsStatus() throws {
        let event = makeEvent()
        try service.markMissed(event)
        XCTAssertEqual(event.status, .missed)
    }

    func testCorrectDose_setsCustomTakenDateAndNote() throws {
        let event = makeEvent()
        let takenAt = event.scheduledDateTime.addingTimeInterval(5 * 60)
        try service.correctDose(event, profile: profile, takenAt: takenAt, note: "Forgot at first")
        XCTAssertEqual(event.userNote, "Forgot at first")
        XCTAssertEqual(event.status, .takenOnTime)
    }
}
