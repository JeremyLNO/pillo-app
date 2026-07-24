import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.services) private var services
    @Environment(\.discreetModeEnabled) private var discreetMode

    @Query(filter: #Predicate<PillProfile> { $0.isActive }) private var profiles: [PillProfile]
    @Query(sort: \DoseEvent.scheduledDate) private var allEvents: [DoseEvent]
    @Query private var notificationPreferencesList: [NotificationPreferences]
    @Query private var stockEntries: [StockEntry]

    @State private var viewModel = HomeViewModel()

    private var profile: PillProfile? { profiles.first }
    private var events: [DoseEvent] {
        guard let profile else { return [] }
        return allEvents.filter { $0.pillProfileID == profile.id }
    }
    private var todayEvent: DoseEvent? {
        events.first { Calendar.current.isDateInToday($0.scheduledDate) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let profile, let services {
                        TodayDoseCard(
                            event: todayEvent,
                            profile: profile,
                            discreetMode: discreetMode,
                            onConfirm: { viewModel.confirm(event: todayEvent!, profile: profile, services: services) },
                            onUndo: { viewModel.undoLastConfirmation(event: todayEvent!, services: services) },
                            onSnooze: { viewModel.reportSnooze(event: todayEvent!, services: services) },
                            onMissed: { services.deepLinkRouter.pendingRoute = .missedPill },
                            canSnooze: todayEvent.map { event in
                                guard let prefs = notificationPreferencesList.first else { return false }
                                return viewModel.canStillSnooze(event: event, preferences: prefs, services: services)
                            } ?? false
                        )

                        WeekStripView(days: weekDays(profile: profile, services: services))

                        BlisterMiniGridView(
                            packPosition: services.pillSchedule.packPosition(for: .now, profile: profile),
                            cellStates: miniGridStates(profile: profile, services: services)
                        )

                        NextBreakBanner(
                            nextBreakDate: services.pillSchedule.nextBreakDate(for: profile, after: .now),
                            nextPackStartDate: services.pillSchedule.nextPackStartDate(for: profile, after: .now),
                            placeboRangeText: nil
                        )

                        HomeStatTilesView(
                            streakDays: streak(profile: profile),
                            observancePercent: observancePercent(profile: profile),
                            remainingPacks: stockEntries.first?.remainingPacks ?? 0
                        )
                    } else {
                        ProgressView()
                    }
                }
                .padding(16)
            }
            .background(Palette.background)
            .navigationTitle(discreetMode ? "" : "Pillo tracker")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if !discreetMode {
                        PilloWordmark(size: 22)
                    }
                }
            }
        }
    }

    private func weekDays(profile: PillProfile, services: ServiceContainer) -> [WeekStripView.WeekDay] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday - calendar.firstWeekday + 7) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else { return [] }

        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: monday) else { return nil }
            let event = events.first { calendar.isDate($0.scheduledDate, inSameDayAs: day) }
            return .init(date: day, status: event?.status, isToday: calendar.isDateInToday(day))
        }
    }

    private func miniGridStates(profile: PillProfile, services: ServiceContainer) -> [BlisterCellState] {
        let position = services.pillSchedule.packPosition(for: .now, profile: profile)
        let calendar = Calendar.current
        return (1...position.packSize).map { day in
            let offset = day - position.dayInPack
            guard let date = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: .now)) else { return .pause }
            let event = events.first { calendar.isDate($0.scheduledDate, inSameDayAs: date) }
            return BlisterCellState.make(event: event, isToday: calendar.isDateInToday(date))
        }
    }

    private func streak(profile: PillProfile) -> Int {
        let calendar = Calendar.current
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

    private func observancePercent(profile: PillProfile) -> Int {
        let dueEvents = events.filter { $0.scheduledDateTime <= .now }
        guard !dueEvents.isEmpty else { return 100 }
        let onTrack = dueEvents.filter { $0.status == .takenOnTime || $0.status == .takenLate || $0.status == .placebo }
        return Int((Double(onTrack.count) / Double(dueEvents.count) * 100).rounded())
    }
}

#Preview {
    HomeView()
        .modelContainer(PersistenceController.preview())
}
