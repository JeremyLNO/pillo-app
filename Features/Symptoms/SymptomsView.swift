import SwiftUI
import SwiftData

/// Facultative symptom tracking (spec section 15) — no automatic medical interpretation
/// is ever shown alongside these entries, just the raw log the user chose to keep.
struct SymptomsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SymptomEntry.date, order: .reverse) private var entries: [SymptomEntry]

    @State private var viewModel = SymptomsViewModel()
    @State private var showLogSheet = false

    var body: some View {
        List {
            Section {
                Button {
                    showLogSheet = true
                } label: {
                    Label(String(localized: "symptoms.logToday"), systemImage: "plus.circle.fill")
                }
            }

            Section(String(localized: "symptoms.history")) {
                if entries.isEmpty {
                    Text("symptoms.empty")
                        .foregroundStyle(Palette.textSecondary)
                } else {
                    ForEach(entries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.date, format: .dateTime.day().month().year())
                                .font(Typography.subheadline)
                            Text(summary(for: entry))
                                .font(Typography.caption)
                                .foregroundStyle(Palette.textSecondary)
                            if let notes = entry.customNotes, !notes.isEmpty {
                                Text(notes).font(Typography.caption)
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .navigationTitle(Text("history.symptoms.title"))
        .sheet(isPresented: $showLogSheet) {
            SymptomLogSheet(viewModel: viewModel) {
                modelContext.insert(viewModel.makeEntry())
                try? modelContext.save()
                viewModel.reset()
                showLogSheet = false
            } onCancel: {
                viewModel.reset()
                showLogSheet = false
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
        try? modelContext.save()
    }

    private func summary(for entry: SymptomEntry) -> String {
        var parts: [String] = []
        if entry.bleeding { parts.append(String(localized: "symptom.bleeding")) }
        if entry.spotting { parts.append(String(localized: "symptom.spotting")) }
        if entry.migraine { parts.append(String(localized: "symptom.headache")) }
        if entry.nausea { parts.append(String(localized: "symptoms.nausea")) }
        if entry.acne { parts.append(String(localized: "symptoms.acne")) }
        if let mood = entry.mood, !mood.isEmpty { parts.append(mood) }
        return parts.isEmpty ? String(localized: "symptoms.noneNoted") : parts.joined(separator: " · ")
    }
}

private struct SymptomLogSheet: View {
    @Bindable var viewModel: SymptomsViewModel
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Toggle(String(localized: "symptom.bleeding"), isOn: $viewModel.bleeding)
                Toggle(String(localized: "symptom.spotting"), isOn: $viewModel.spotting)
                Toggle(String(localized: "symptom.headache"), isOn: $viewModel.migraine)
                Toggle(String(localized: "symptoms.nausea"), isOn: $viewModel.nausea)
                Toggle(String(localized: "symptoms.acne"), isOn: $viewModel.acne)

                Section {
                    Toggle(String(localized: "symptoms.trackPain"), isOn: $viewModel.trackPain)
                    if viewModel.trackPain {
                        Slider(value: $viewModel.painLevel, in: 0...10, step: 1) {
                            Text("symptoms.painLevel")
                        }
                        Text(String(format: String(localized: "symptoms.painLevel.value"), Int(viewModel.painLevel)))
                            .font(Typography.caption)
                            .foregroundStyle(Palette.textSecondary)
                    }
                }

                Section(String(localized: "symptom.mood")) {
                    TextField(String(localized: "symptoms.mood.placeholder"), text: $viewModel.mood)
                }

                Section(String(localized: "symptoms.notes")) {
                    TextField(String(localized: "symptoms.notes.placeholder"), text: $viewModel.customNotes, axis: .vertical)
                }
            }
            .navigationTitle(Text("symptoms.logToday"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel"), action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save"), action: onSave)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SymptomsView()
            .modelContainer(PersistenceController.preview())
    }
}
