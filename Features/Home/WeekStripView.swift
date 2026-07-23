import SwiftUI

struct WeekStripView: View {
    let days: [WeekDay]

    struct WeekDay: Identifiable {
        let id = UUID()
        let date: Date
        let status: DoseStatus?
        let isToday: Bool
    }

    var body: some View {
        Card {
            HStack {
                ForEach(days) { day in
                    VStack(spacing: 8) {
                        Text(day.date, format: .dateTime.weekday(.narrow))
                            .font(Typography.caption)
                            .foregroundStyle(Palette.textSecondary)

                        ZStack {
                            Circle()
                                .fill(day.isToday ? Palette.primary : color(for: day.status).opacity(day.status == nil ? 0 : 0.18))
                                .frame(width: 30, height: 30)
                            icon(for: day.status)
                                .foregroundStyle(day.isToday ? .white : color(for: day.status))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func icon(for status: DoseStatus?) -> some View {
        switch status {
        case .takenOnTime, .takenLate, .placebo:
            Image(systemName: "checkmark").font(.caption.bold())
        case .missed:
            Image(systemName: "xmark").font(.caption.bold())
        default:
            EmptyView()
        }
    }

    private func color(for status: DoseStatus?) -> Color {
        switch status {
        case .takenOnTime, .placebo: return Palette.success
        case .takenLate: return Palette.warning
        case .missed: return Palette.danger
        default: return Palette.textSecondary
        }
    }
}

#Preview {
    WeekStripView(days: (0..<7).map { .init(date: Calendar.current.date(byAdding: .day, value: $0 - 3, to: .now)!, status: $0 < 5 ? .takenOnTime : nil, isToday: $0 == 3) })
        .padding()
        .background(Palette.background)
}
