import XCTest
import SwiftData
@testable import Pillo

/// `PilloTests` is injected into the `Pillo.app` process (via `TEST_HOST`), so it runs
/// with the host app's own entitlements — including the App Group — making this the
/// right place to verify the actual widget data pipeline end to end: `WidgetBridge`
/// computes a snapshot from real models, `WidgetSnapshotStore` round-trips it through
/// the same shared UserDefaults suite the widget extension reads from.
@MainActor
final class WidgetBridgeTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var profile: PillProfile!

    override func setUp() {
        super.setUp()
        let schema = Schema([PillProfile.self, DoseEvent.self])
        container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        context = container.mainContext

        let startDate = Calendar.current.date(byAdding: .day, value: -11, to: .now)!
        profile = PillProfile(
            displayName: "Test Pill",
            usualIntakeTime: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: .now)!,
            startDate: startDate,
            allowedDelayMinutes: 720
        )
        context.insert(profile)
    }

    private func makeEvent(dayOffset: Int, status: DoseStatus, taken: Bool) -> DoseEvent {
        let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: Calendar.current.startOfDay(for: .now))!
        let event = DoseEvent(pillProfileID: profile.id, scheduledDate: date, scheduledTime: profile.usualIntakeTime, status: status)
        if taken { event.actualTakenDate = date }
        context.insert(event)
        return event
    }

    func testRefreshWritesReadableSnapshotWithCorrectNextDose() throws {
        let yesterday = makeEvent(dayOffset: -1, status: .takenOnTime, taken: true)
        let today = makeEvent(dayOffset: 0, status: .scheduled, taken: false)
        _ = yesterday

        let pillSchedule = PillScheduleService(context: context)
        let watchConnectivity = NoOpWatchConnectivity()
        let userPreferences = UserPreferences()

        WidgetBridge.refresh(
            profile: profile,
            events: [yesterday, today],
            userPreferences: userPreferences,
            pillSchedule: pillSchedule,
            watchConnectivity: watchConnectivity
        )

        let snapshot = WidgetSnapshotStore.read()
        XCTAssertTrue(snapshot.hasActiveProfile)
        XCTAssertEqual(snapshot.nextDoseEventID, today.id)
        XCTAssertFalse(snapshot.nextDoseIsConfirmed)
        XCTAssertEqual(snapshot.streakDays, 0) // today isn't confirmed yet
        XCTAssertFalse(snapshot.blisterCells.isEmpty)
    }

    func testRefreshWithNoProfileWritesEmptySnapshot() throws {
        let pillSchedule = PillScheduleService(context: context)
        WidgetBridge.refresh(
            profile: nil,
            events: [],
            userPreferences: nil,
            pillSchedule: pillSchedule,
            watchConnectivity: NoOpWatchConnectivity()
        )
        let snapshot = WidgetSnapshotStore.read()
        XCTAssertFalse(snapshot.hasActiveProfile)
        XCTAssertNil(snapshot.nextDoseEventID)
    }

    func testMarkDoseTakenIntentPatchMatchesRealConfirmation() throws {
        let today = makeEvent(dayOffset: 0, status: .scheduled, taken: false)
        let pillSchedule = PillScheduleService(context: context)
        WidgetBridge.refresh(profile: profile, events: [today], userPreferences: UserPreferences(), pillSchedule: pillSchedule, watchConnectivity: NoOpWatchConnectivity())

        XCTAssertEqual(WidgetSnapshotStore.read().nextDoseEventID, today.id)

        // Simulate what the widget's AppIntent does: confirm via the same DoseTrackingService.
        let tracking = DoseTrackingService(context: context, notificationService: nil)
        try tracking.confirmDose(today, profile: profile, takenAt: .now)
        XCTAssertEqual(today.status, .takenOnTime)
    }
}

private final class NoOpWatchConnectivity: WatchConnectivityServicing {
    func activate() {}
    func send(_ snapshot: WidgetSnapshot) {}
}
