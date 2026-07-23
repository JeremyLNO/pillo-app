import WidgetKit

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct ComplicationTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry {
        ComplicationEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (ComplicationEntry) -> Void) {
        completion(ComplicationEntry(date: .now, snapshot: context.isPreview ? .placeholder : WidgetSnapshotStore.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ComplicationEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.read()
        let entry = ComplicationEntry(date: .now, snapshot: snapshot)
        let oneHourFromNow = Date.now.addingTimeInterval(3600)
        let refreshDate = snapshot.nextDoseDate.map { min($0, oneHourFromNow) } ?? oneHourFromNow
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}
