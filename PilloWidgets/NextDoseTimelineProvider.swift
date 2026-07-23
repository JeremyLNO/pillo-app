import WidgetKit

struct NextDoseEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let isPlaceholder: Bool
}

struct NextDoseTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextDoseEntry {
        NextDoseEntry(date: .now, snapshot: .placeholder, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextDoseEntry) -> Void) {
        if context.isPreview {
            completion(NextDoseEntry(date: .now, snapshot: .placeholder, isPlaceholder: true))
        } else {
            completion(NextDoseEntry(date: .now, snapshot: WidgetSnapshotStore.read(), isPlaceholder: false))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextDoseEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.read()
        let entry = NextDoseEntry(date: .now, snapshot: snapshot, isPlaceholder: false)

        // Refresh at the next dose time (so "Due in Xmin" flips to "Overdue") or in an
        // hour, whichever is sooner — the countdown text itself re-renders continuously
        // between refreshes via `Text(_:style:)`, so this doesn't need to be frequent.
        let oneHourFromNow = Date.now.addingTimeInterval(3600)
        let refreshDate = snapshot.nextDoseDate.map { min($0, oneHourFromNow) } ?? oneHourFromNow
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}
