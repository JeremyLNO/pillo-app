import Foundation
import Observation

@Observable
@MainActor
final class HistoryViewModel {
    var displayedMonth: Date = .now
    var showAddNoteSheet = false
    var noteText: String = ""

    func goToPreviousMonth() {
        displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }

    func goToNextMonth() {
        displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }

    func saveNote(for date: Date, context: (Date, String) -> Void) {
        guard !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        context(date, noteText)
        noteText = ""
        showAddNoteSheet = false
    }
}
