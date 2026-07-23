import XCTest
@testable import Pillo

final class AdaptiveReminderCalculatorTests: XCTestCase {
    private let profileID = UUID()

    private func makeEvent(daysAgo: Int, delayMinutes: Int, status: DoseStatus = .takenLate) -> DoseEvent {
        let scheduledDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        let event = DoseEvent(pillProfileID: profileID, scheduledDate: scheduledDate, scheduledTime: scheduledDate, status: status)
        event.actualTakenDate = event.scheduledDateTime.addingTimeInterval(TimeInterval(delayMinutes * 60))
        event.delayMinutes = delayMinutes
        return event
    }

    func testNotEnoughHistory_returnsNil() {
        let events = (0..<3).map { makeEvent(daysAgo: $0, delayMinutes: 15) }
        XCTAssertNil(AdaptiveReminderCalculator.suggestedOffsetMinutes(from: events))
    }

    func testConsistentDelay_suggestsMedianOffset() {
        let events = (0..<6).map { makeEvent(daysAgo: $0, delayMinutes: 12) }
        XCTAssertEqual(AdaptiveReminderCalculator.suggestedOffsetMinutes(from: events), 12)
    }

    func testAlreadyOnTime_returnsNil() {
        let events = (0..<6).map { makeEvent(daysAgo: $0, delayMinutes: 0, status: .takenOnTime) }
        XCTAssertNil(AdaptiveReminderCalculator.suggestedOffsetMinutes(from: events))
    }

    func testInconsistentDelays_returnsNil() {
        let delays = [0, 5, 90, 10, 120, 15]
        let events = delays.enumerated().map { index, delay in makeEvent(daysAgo: index, delayMinutes: delay) }
        XCTAssertNil(AdaptiveReminderCalculator.suggestedOffsetMinutes(from: events))
    }

    func testOffsetIsCappedAtMaximum() {
        let events = (0..<6).map { makeEvent(daysAgo: $0, delayMinutes: 500) }
        XCTAssertEqual(AdaptiveReminderCalculator.suggestedOffsetMinutes(from: events), AdaptiveReminderCalculator.maximumOffsetMinutes)
    }

    func testIgnoresUnconfirmedAndMissedEvents() {
        var events = (0..<6).map { makeEvent(daysAgo: $0, delayMinutes: 12) }
        let missed = DoseEvent(pillProfileID: profileID, scheduledDate: .now, scheduledTime: .now, status: .missed)
        events.append(missed)
        XCTAssertEqual(AdaptiveReminderCalculator.suggestedOffsetMinutes(from: events), 12)
    }
}
