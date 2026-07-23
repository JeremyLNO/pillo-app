import WidgetKit
import SwiftUI

struct PilloComplication: Widget {
    let kind = "PilloComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ComplicationTimelineProvider()) { entry in
            ComplicationEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName(Text("widget.displayName"))
        .description(Text("widget.description"))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct ComplicationEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ComplicationEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.snapshot.discreetMode ? "widget.title.discreet" : "widget.title")
                    .font(.caption2)
                if let date = entry.snapshot.nextDoseDate {
                    Text(date, style: .time).font(.headline)
                } else {
                    Text("widget.noneToday").font(.caption2)
                }
            }
        case .accessoryInline:
            if let date = entry.snapshot.nextDoseDate {
                Label { Text(date, style: .time) } icon: { Image(systemName: "pills.fill") }
            } else {
                Text("widget.noneToday")
            }
        case .accessoryCorner:
            if let date = entry.snapshot.nextDoseDate {
                Text(date, style: .time)
                    .widgetLabel {
                        ProgressView(value: Double(entry.snapshot.dayInPack), total: Double(max(entry.snapshot.packSize, 1)))
                    }
            } else {
                Image(systemName: "pills.fill")
            }
        default:
            Gauge(value: Double(entry.snapshot.dayInPack), in: 0...Double(max(entry.snapshot.packSize, 1))) {
                Image(systemName: "pills.fill")
            } currentValueLabel: {
                if let date = entry.snapshot.nextDoseDate {
                    Text(date, style: .time)
                        .font(.system(size: 12, weight: .semibold))
                        .minimumScaleFactor(0.6)
                } else {
                    Text("—")
                }
            }
            .gaugeStyle(.accessoryCircular)
        }
    }
}
