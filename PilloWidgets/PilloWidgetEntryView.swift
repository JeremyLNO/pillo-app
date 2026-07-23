import SwiftUI
import WidgetKit

struct PilloWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NextDoseEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge, .systemExtraLarge:
                LargeWidgetView(entry: entry)
            case .accessoryCircular:
                CircularAccessoryView(entry: entry)
            case .accessoryRectangular:
                RectangularAccessoryView(entry: entry)
            case .accessoryInline:
                InlineAccessoryView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        .redacted(reason: entry.isPlaceholder ? .placeholder : [])
    }
}

/// Shared by every Home Screen family — "no profile yet" state.
struct WidgetOnboardingPromptView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "pills.fill")
                .font(.title2)
                .foregroundStyle(Palette.primary)
            Text("widget.onboardingPrompt")
                .font(.caption)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct SmallWidgetView: View {
    let entry: NextDoseEntry

    var body: some View {
        if !entry.snapshot.hasActiveProfile {
            WidgetOnboardingPromptView()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.snapshot.discreetMode ? "widget.title.discreet" : "widget.title")
                    .font(.caption2)
                    .foregroundStyle(Palette.textSecondary)

                if let date = entry.snapshot.nextDoseDate {
                    Text(date, style: .time)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(Palette.textPrimary)
                        .minimumScaleFactor(0.7)

                    if entry.snapshot.nextDoseIsConfirmed {
                        Label(String(localized: "widget.confirmed"), systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Palette.success)
                    } else {
                        Text(date, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(Palette.textSecondary)
                    }
                } else {
                    Text("widget.noneToday")
                        .font(.caption)
                        .foregroundStyle(Palette.textSecondary)
                }

                Spacer(minLength: 4)

                if !entry.snapshot.nextDoseIsConfirmed,
                   let eventID = entry.snapshot.nextDoseEventID,
                   let profileID = entry.snapshot.nextProfileID {
                    Button(intent: MarkDoseTakenIntent(doseEventID: eventID, profileID: profileID)) {
                        Label(String(localized: "widget.confirmButton"), systemImage: "checkmark")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.primary)
                }
            }
            .padding(4)
        }
    }
}

struct MediumWidgetView: View {
    let entry: NextDoseEntry

    var body: some View {
        if !entry.snapshot.hasActiveProfile {
            WidgetOnboardingPromptView()
        } else {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.snapshot.discreetMode ? "widget.title.discreet" : "widget.title")
                        .font(.caption2)
                        .foregroundStyle(Palette.textSecondary)
                    if let date = entry.snapshot.nextDoseDate {
                        Text(date, style: .time)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(Palette.textPrimary)
                        Text(entry.snapshot.nextDoseIsConfirmed ? String(localized: "widget.confirmed") : "")
                            .font(.caption2)
                            .foregroundStyle(Palette.success)
                    }
                    Spacer(minLength: 4)
                    if !entry.snapshot.nextDoseIsConfirmed,
                       let eventID = entry.snapshot.nextDoseEventID,
                       let profileID = entry.snapshot.nextProfileID {
                        Button(intent: MarkDoseTakenIntent(doseEventID: eventID, profileID: profileID)) {
                            Label(String(localized: "widget.confirmButton"), systemImage: "checkmark")
                                .font(.caption.bold())
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.primary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 10) {
                    widgetStat(icon: "flame.fill", value: "\(entry.snapshot.streakDays)", color: Palette.warning)
                    widgetStat(icon: "number", value: "\(entry.snapshot.dayInPack)/\(entry.snapshot.packSize)", color: Palette.primary)
                    widgetStat(icon: "checkmark.shield.fill", value: "\(entry.snapshot.observancePercent)%", color: Palette.success)
                }
            }
            .padding(4)
        }
    }

    private func widgetStat(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.caption.bold()).foregroundStyle(Palette.textPrimary)
        }
    }
}

struct LargeWidgetView: View {
    let entry: NextDoseEntry
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        if !entry.snapshot.hasActiveProfile {
            WidgetOnboardingPromptView()
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.snapshot.discreetMode ? "widget.title.discreet" : "widget.title")
                            .font(.caption2)
                            .foregroundStyle(Palette.textSecondary)
                        if let date = entry.snapshot.nextDoseDate {
                            Text(date, style: .time)
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(Palette.textPrimary)
                        }
                    }
                    Spacer()
                    Text(String(format: String(localized: "home.blisterMini.dayProgress"), entry.snapshot.dayInPack, entry.snapshot.packSize))
                        .font(.caption)
                        .foregroundStyle(Palette.textSecondary)
                }

                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(entry.snapshot.blisterCells, id: \.dayNumber) { cell in
                        BlisterCellView(
                            dayNumber: cell.dayNumber,
                            state: BlisterCellState.make(rawStatus: cell.statusRaw),
                            showsNumber: false
                        )
                        .frame(height: 16)
                    }
                }

                Spacer(minLength: 2)

                if !entry.snapshot.nextDoseIsConfirmed,
                   let eventID = entry.snapshot.nextDoseEventID,
                   let profileID = entry.snapshot.nextProfileID {
                    Button(intent: MarkDoseTakenIntent(doseEventID: eventID, profileID: profileID)) {
                        Label(String(localized: "widget.confirmButton"), systemImage: "checkmark")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.primary)
                } else {
                    Label(String(localized: "widget.confirmed"), systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Palette.success)
                }
            }
            .padding(4)
        }
    }
}

struct CircularAccessoryView: View {
    let entry: NextDoseEntry

    var body: some View {
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

struct RectangularAccessoryView: View {
    let entry: NextDoseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.snapshot.discreetMode ? "widget.title.discreet" : "widget.title")
                .font(.caption2)
            if let date = entry.snapshot.nextDoseDate {
                Text(date, style: .time)
                    .font(.headline)
                Text(entry.snapshot.nextDoseIsConfirmed ? String(localized: "widget.confirmed") : "")
                    .font(.caption2)
            } else {
                Text("widget.noneToday")
                    .font(.caption)
            }
        }
    }
}

struct InlineAccessoryView: View {
    let entry: NextDoseEntry

    var body: some View {
        if let date = entry.snapshot.nextDoseDate {
            Label {
                Text(date, style: .time)
            } icon: {
                Image(systemName: "pills.fill")
            }
        } else {
            Text("widget.noneToday")
        }
    }
}
