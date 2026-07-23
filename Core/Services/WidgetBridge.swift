import Foundation

/// Recomputes the display-ready `WidgetSnapshot` and writes it to the App Group (for the
/// iOS widgets) and forwards it to the paired Watch (for complications). App-only — needs
/// `PillScheduleServicing`, which isn't shared into the widget extension (the widget only
/// reads the snapshot; the AppIntent does its own minimal optimistic patch instead of a
/// full recompute — see `PilloWidgets/MarkDoseTakenIntent.swift`).
@MainActor
enum WidgetBridge {
    static func refresh(profile: PillProfile?, events: [DoseEvent], userPreferences: UserPreferences?, pillSchedule: PillScheduleServicing, watchConnectivity: WatchConnectivityServicing) {
        guard let profile, let userPreferences else {
            WidgetSnapshotStore.write(.empty)
            watchConnectivity.send(.empty)
            return
        }

        let calendar = Calendar.current
        let position = pillSchedule.packPosition(for: .now, profile: profile)
        let packStart = calendar.date(byAdding: .day, value: -(position.dayInPack - 1), to: calendar.startOfDay(for: .now)) ?? .now

        let cells: [WidgetSnapshot.BlisterCell] = (1...position.packSize).map { day in
            let date = calendar.date(byAdding: .day, value: day - 1, to: packStart) ?? packStart
            let event = events.first { calendar.isDate($0.scheduledDate, inSameDayAs: date) }
            let state = BlisterCellState.make(event: event, isToday: calendar.isDateInToday(date))
            return WidgetSnapshot.BlisterCell(dayNumber: day, statusRaw: state.rawValue)
        }

        let nextDose = events
            .filter { $0.status == .scheduled || $0.status == .unknown || $0.status == .placebo }
            .filter { $0.scheduledDateTime >= calendar.startOfDay(for: .now) }
            .sorted { $0.scheduledDateTime < $1.scheduledDateTime }
            .first

        let snapshot = WidgetSnapshot(
            generatedAt: .now,
            hasActiveProfile: true,
            discreetMode: userPreferences.discreetModeEnabled,
            nextDoseEventID: nextDose?.id,
            nextProfileID: profile.id,
            nextDoseDate: nextDose?.scheduledDateTime,
            nextDoseIsConfirmed: nextDose?.actualTakenDate != nil,
            dayInPack: position.dayInPack,
            packSize: position.packSize,
            blisterCells: cells,
            streakDays: streak(events: events, calendar: calendar),
            observancePercent: observancePercent(events: events)
        )
        WidgetSnapshotStore.write(snapshot)
        watchConnectivity.send(snapshot)
    }

    private static func streak(events: [DoseEvent], calendar: Calendar) -> Int {
        var count = 0
        var day = calendar.startOfDay(for: .now)
        while true {
            guard let event = events.first(where: { calendar.isDate($0.scheduledDate, inSameDayAs: day) }) else { break }
            guard event.actualTakenDate != nil, event.status != .missed else { break }
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    private static func observancePercent(events: [DoseEvent]) -> Int {
        let dueEvents = events.filter { $0.scheduledDateTime <= .now }
        guard !dueEvents.isEmpty else { return 100 }
        let onTrack = dueEvents.filter { $0.status == .takenOnTime || $0.status == .takenLate || $0.status == .placebo }
        return Int((Double(onTrack.count) / Double(dueEvents.count) * 100).rounded())
    }
}
