import WidgetKit
import SwiftUI

struct PilloNextDoseWidget: Widget {
    let kind = "PilloNextDoseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextDoseTimelineProvider()) { entry in
            PilloWidgetEntryView(entry: entry)
                .containerBackground(Palette.background, for: .widget)
        }
        .configurationDisplayName(Text("widget.displayName"))
        .description(Text("widget.description"))
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline,
        ])
    }
}

#Preview(as: .systemSmall) {
    PilloNextDoseWidget()
} timeline: {
    NextDoseEntry(date: .now, snapshot: .placeholder, isPlaceholder: false)
}

#Preview(as: .systemMedium) {
    PilloNextDoseWidget()
} timeline: {
    NextDoseEntry(date: .now, snapshot: .placeholder, isPlaceholder: false)
}

#Preview(as: .systemLarge) {
    PilloNextDoseWidget()
} timeline: {
    NextDoseEntry(date: .now, snapshot: .placeholder, isPlaceholder: false)
}
