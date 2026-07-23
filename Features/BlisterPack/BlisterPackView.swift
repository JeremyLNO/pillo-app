import SwiftUI
import SwiftData

struct BlisterPackView: View {
    @Environment(\.services) private var services
    @Query(filter: #Predicate<PillProfile> { $0.isActive }) private var profiles: [PillProfile]
    @Query(sort: \DoseEvent.scheduledDate) private var allEvents: [DoseEvent]
    @Query private var stockEntries: [StockEntry]

    @State private var viewModel = BlisterPackViewModel()

    private var profile: PillProfile? { profiles.first }
    private var events: [DoseEvent] {
        guard let profile else { return [] }
        return allEvents.filter { $0.pillProfileID == profile.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile, let services {
                    let position = services.pillSchedule.packPosition(for: .now, profile: profile)
                    let calendar = Calendar.current
                    let packStart = calendar.date(byAdding: .day, value: -(position.dayInPack - 1), to: calendar.startOfDay(for: .now)) ?? .now
                    let states = (1...position.packSize).map { day -> BlisterCellState in
                        let date = calendar.date(byAdding: .day, value: day - 1, to: packStart) ?? packStart
                        let event = events.first { calendar.isDate($0.scheduledDate, inSameDayAs: date) }
                        return BlisterCellState.make(event: event, isToday: calendar.isDateInToday(date))
                    }

                    VStack(spacing: 20) {
                        Card {
                            HStack(spacing: 20) {
                                ProgressRing(
                                    progress: Double(position.dayInPack) / Double(position.packSize),
                                    label: String(localized: "blister.dayLabel"),
                                    value: "\(position.dayInPack)/\(position.packSize)"
                                )
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(profile.displayName)
                                        .font(Typography.headline)
                                    Text(profile.pillType == .combined ? "pillType.combined" : "pillType.progestinOnly")
                                        .font(Typography.caption)
                                        .foregroundStyle(Palette.textSecondary)
                                }
                                Spacer()
                            }
                        }

                        Card {
                            VStack(alignment: .leading, spacing: 14) {
                                BlisterGridView(packPosition: position, cellStates: states) { day in
                                    let date = calendar.date(byAdding: .day, value: day - 1, to: packStart) ?? packStart
                                    if let event = events.first(where: { calendar.isDate($0.scheduledDate, inSameDayAs: date) }) {
                                        viewModel.beginCorrection(event)
                                    }
                                }
                                BlisterLegendView()
                            }
                        }

                        if let todayEvent = events.first(where: { calendar.isDateInToday($0.scheduledDate) }), todayEvent.actualTakenDate == nil {
                            PrimaryButton(title: String(localized: "blister.validateToday"), systemImage: "checkmark.circle.fill") {
                                try? services.doseTracking.confirmDose(todayEvent, profile: profile, takenAt: .now)
                            }
                        }
                        SecondaryButton(title: String(localized: "blister.correctPast"), systemImage: "clock.arrow.circlepath") {
                            if let mostRecentPast = events.filter({ $0.scheduledDateTime < .now }).sorted(by: { $0.scheduledDateTime > $1.scheduledDateTime }).first {
                                viewModel.beginCorrection(mostRecentPast)
                            }
                        }

                        NextBreakBanner(
                            nextBreakDate: services.pillSchedule.nextBreakDate(for: profile, after: .now),
                            nextPackStartDate: services.pillSchedule.nextPackStartDate(for: profile, after: .now),
                            placeboRangeText: nil
                        )

                        if let stock = stockEntries.first {
                            StatTile(systemImage: "pills.fill", iconColor: Palette.primary, title: String(localized: "home.stats.stock"), value: "\(stock.remainingPacks)", unit: String(localized: "home.stats.packs"))
                        }
                    }
                    .padding(16)
                } else {
                    ProgressView().padding()
                }
            }
            .background(Palette.background)
            .navigationTitle(Text("tab.blister"))
            .sheet(item: $viewModel.correctingEvent) { event in
                CorrectPastDoseSheet(
                    event: event,
                    onSave: { takenAt, note in
                        if let profile, let services {
                            viewModel.applyCorrection(takenAt: takenAt, note: note, profile: profile, services: services)
                        }
                    },
                    onCancel: { viewModel.cancelCorrection() }
                )
            }
        }
    }
}

#Preview {
    BlisterPackView()
        .modelContainer(PersistenceController.preview())
}
