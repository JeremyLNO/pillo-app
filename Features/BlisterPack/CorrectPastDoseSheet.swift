import SwiftUI

struct CorrectPastDoseSheet: View {
    let event: DoseEvent
    let onSave: (Date?, String?) -> Void
    let onCancel: () -> Void

    @State private var wasTaken: Bool
    @State private var takenAt: Date
    @State private var note: String

    init(event: DoseEvent, onSave: @escaping (Date?, String?) -> Void, onCancel: @escaping () -> Void) {
        self.event = event
        self.onSave = onSave
        self.onCancel = onCancel
        _wasTaken = State(initialValue: event.actualTakenDate != nil)
        _takenAt = State(initialValue: event.actualTakenDate ?? event.scheduledDateTime)
        _note = State(initialValue: event.userNote ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(String(localized: "blister.correct.wasTaken"), isOn: $wasTaken)
                    if wasTaken {
                        DatePicker(String(localized: "blister.correct.takenAt"), selection: $takenAt)
                    }
                }
                Section(String(localized: "blister.correct.note")) {
                    TextField(String(localized: "blister.correct.note.placeholder"), text: $note, axis: .vertical)
                }
            }
            .navigationTitle(Text("blister.correct.title"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel"), action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save")) {
                        onSave(wasTaken ? takenAt : nil, note.isEmpty ? nil : note)
                    }
                }
            }
        }
    }
}
