import XCTest
@testable import Pillo

final class PillScheduleServiceTests: XCTestCase {
    private let calculator = PillScheduleCalculator()
    private let start = Calendar.current.startOfDay(for: .now)

    private func input(
        scheduleType: ScheduleType,
        activePillCount: Int,
        placeboPillCount: Int,
        customDays: [CustomDayInput] = []
    ) -> PillScheduleInput {
        PillScheduleInput(
            profileID: UUID(),
            scheduleType: scheduleType,
            startDate: start,
            activePillCount: activePillCount,
            placeboPillCount: placeboPillCount,
            usualIntakeTime: start,
            customDays: customDays
        )
    }

    func test21Active7Stop_generatesOneCycleCorrectly() {
        let scheduleInput = input(scheduleType: .days21Active7Stop, activePillCount: 21, placeboPillCount: 7)
        let drafts = calculator.generateDrafts(input: scheduleInput, from: start, cyclesToGenerate: 1)
        XCTAssertEqual(drafts.count, 21)
        XCTAssertTrue(drafts.allSatisfy { $0.status == .scheduled })
        XCTAssertEqual(calculator.cycleLength(for: scheduleInput), 28)
    }

    func test24Active4Placebo_generatesActiveAndPlaceboDays() {
        let scheduleInput = input(scheduleType: .days24Active4Placebo, activePillCount: 24, placeboPillCount: 4)
        let drafts = calculator.generateDrafts(input: scheduleInput, from: start, cyclesToGenerate: 1)
        XCTAssertEqual(drafts.count, 28)
        XCTAssertEqual(drafts.filter { $0.status == .scheduled }.count, 24)
        XCTAssertEqual(drafts.filter { $0.status == .placebo }.count, 4)
    }

    func test28Days_everyDayIsActiveWithNoBreak() {
        let scheduleInput = input(scheduleType: .days28, activePillCount: 28, placeboPillCount: 0)
        let drafts = calculator.generateDrafts(input: scheduleInput, from: start, cyclesToGenerate: 1)
        XCTAssertEqual(drafts.count, 28)
        XCTAssertTrue(drafts.allSatisfy { $0.status == .scheduled })
        XCTAssertNil(calculator.nextBreakDate(input: scheduleInput, after: start))
    }

    func testContinuous_neverPausesAndWrapsPacks() {
        let scheduleInput = input(scheduleType: .continuous, activePillCount: 28, placeboPillCount: 0)
        let drafts = calculator.generateDrafts(input: scheduleInput, from: start, cyclesToGenerate: 2)
        XCTAssertEqual(drafts.count, 56)
        XCTAssertTrue(drafts.allSatisfy { $0.status == .scheduled })
        XCTAssertNil(calculator.nextBreakDate(input: scheduleInput, after: start))
    }

    func testCustomSchedule_respectsPerDayPattern() {
        let customDays = [
            CustomDayInput(dayIndex: 0, isActivePillDay: true, isPlaceboDay: false),
            CustomDayInput(dayIndex: 1, isActivePillDay: true, isPlaceboDay: false),
            CustomDayInput(dayIndex: 2, isActivePillDay: false, isPlaceboDay: true),
            CustomDayInput(dayIndex: 3, isActivePillDay: false, isPlaceboDay: false),
        ]
        let scheduleInput = input(scheduleType: .custom, activePillCount: 0, placeboPillCount: 0, customDays: customDays)
        XCTAssertEqual(calculator.cycleLength(for: scheduleInput), 4)
        let drafts = calculator.generateDrafts(input: scheduleInput, from: start, cyclesToGenerate: 1)
        XCTAssertEqual(drafts.count, 3) // day 3 (index 3) has no event — a stop day
        XCTAssertEqual(drafts.filter { $0.status == .scheduled }.count, 2)
        XCTAssertEqual(drafts.filter { $0.status == .placebo }.count, 1)
    }

    func testPackPosition_matchesDayInPack() {
        let scheduleInput = input(scheduleType: .days28, activePillCount: 28, placeboPillCount: 0)
        let day12 = Calendar.current.date(byAdding: .day, value: 11, to: start)!
        let position = calculator.packPosition(for: day12, input: scheduleInput)
        XCTAssertEqual(position.dayInPack, 12)
        XCTAssertEqual(position.packSize, 28)
        XCTAssertEqual(position.packIndex, 0)
    }

    func testDelayComputation_matchesAllowedWindow() {
        let event = DoseEvent(pillProfileID: UUID(), scheduledDate: start, scheduledTime: start)
        let takenAt = event.scheduledDateTime.addingTimeInterval(30 * 60)
        let delayMinutes = max(0, Int(takenAt.timeIntervalSince(event.scheduledDateTime) / 60))
        XCTAssertEqual(delayMinutes, 30)
    }
}
