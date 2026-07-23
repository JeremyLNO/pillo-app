import SwiftUI

struct AddNoteSheet: View {
    @Binding var text: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField(String(localized: "history.addNote.placeholder"), text: $text, axis: .vertical)
                    .lineLimit(4...8)
            }
            .navigationTitle(Text("history.addNote.title"))
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
