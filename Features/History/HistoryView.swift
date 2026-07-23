import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.services) private var services
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<PillProfile> { $0.isActive }) private var profiles: [PillProfile]
    @Query(sort: \DoseEvent.scheduledDate) private var allEvents: [DoseEvent]

    @State private var viewModel = HistoryViewModel()
    @State private var exportURL: URL?
    @State private var showExportOptions = false

    private var profile: PillProfile? { profiles.first }
    private var events: [DoseEvent] {
        guard let profile else { return [] }
        return allEvents.filter { $0.pillProfileID == profile.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if profile != nil {
                        HStack(spacing: 12) {
                            StatTile(systemImage: "checkmark.shield.fill", iconColor: Palette.success, title: String(localized: "home.stats.observance"), value: "\(observancePercent())", unit: "%")
                            StatTile(systemImage: "clock.badge.exclamationmark.fill", iconColor: Palette.warning, title: String(localized: "history.stats.delays"), value: "\(delayCountThisMonth())", unit: String(localized: "history.stats.thisMonth"))
                            StatTile(systemImage: "flame.fill", iconColor: Palette.warning, title: String(localized: "home.stats.streak"), value: "\(streak())", unit: String(localized: "home.stats.days"))
                        }

                        MonthCalendarGridView(
                            month: viewModel.displayedMonth,
                            events: events,
                            onPrevious: viewModel.goToPreviousMonth,
                            onNext: viewModel.goToNextMonth
                        )

                        RegularityBarChartView(points: last28DaysPoints())

                        NavigationLink {
                            SymptomsView()
                        } label: {
                            SymptomChipsView()
                        }
                        .buttonStyle(.plain)

                        PrimaryButton(title: String(localized: "history.addNote"), systemImage: "square.and.pencil") {
                            viewModel.showAddNoteSheet = true
                        }
                    } else {
                        ProgressView()
                    }
                }
                .padding(16)
            }
            .background(Palette.background)
            .navigationTitle(Text("history.navTitle"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            showExportOptions = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .confirmationDialog(Text("history.export.chooseFormat"), isPresented: $showExportOptions, titleVisibility: .visible) {
                Button(String(localized: "history.export.csv")) { export(format: .csv) }
                Button(String(localized: "history.export.pdf")) { export(format: .pdf) }
                Button(String(localized: "common.cancel"), role: .cancel) {}
            }
            .sheet(isPresented: $viewModel.showAddNoteSheet) {
                AddNoteSheet(
                    text: $viewModel.noteText,
                    onSave: {
                        viewModel.saveNote(for: .now) { date, note in
                            let entry = SymptomEntry(date: date, customNotes: note)
                            modelContext.insert(entry)
                            try? modelContext.save()
                        }
                    },
                    onCancel: { viewModel.showAddNoteSheet = false }
                )
            }
        }
    }

    private func export(format: HistoryExportFormat) {
        guard let services, let profile else { return }
        exportURL = try? services.historyExport.export(events: events, profileName: profile.displayName, format: format)
    }

    private func streak() -> Int {
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

    private func observancePercent() -> Int {
        let dueEvents = events.filter { $0.scheduledDateTime <= .now }
        guard !dueEvents.isEmpty else { return 100 }
        let onTrack = dueEvents.filter { $0.status == .takenOnTime || $0.status == .takenLate || $0.status == .placebo }
        return Int((Double(onTrack.count) / Double(dueEvents.count) * 100).rounded())
    }

    private func delayCountThisMonth() -> Int {
        let calendar = Calendar.current
        return events.filter {
            $0.status == .takenLate && calendar.isDate($0.scheduledDate, equalTo: .now, toGranularity: .month)
        }.count
    }

    private func last28DaysPoints() -> [RegularityBarChartView.DayPoint] {
        let calendar = Calendar.current
        return (0..<28).reversed().compactMap { offset -> RegularityBarChartView.DayPoint? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: .now)) else { return nil }
            let event = events.first { calendar.isDate($0.scheduledDate, inSameDayAs: date) }
            let onTrack = event?.status == .takenOnTime || event?.status == .placebo
            return .init(date: date, onTrack: onTrack, hasEvent: event != nil)
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(PersistenceController.preview())
}
