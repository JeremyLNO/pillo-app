import SwiftUI

struct MonthCalendarGridView: View {
    let month: Date
    let events: [DoseEvent]
    let onPrevious: () -> Void
    let onNext: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(month, format: .dateTime.month(.wide).year())
                        .font(Typography.headline)
                    Spacer()
                    Button(action: onPrevious) { Image(systemName: "chevron.left") }
                    Button(action: onNext) { Image(systemName: "chevron.right") }
                }
                .foregroundStyle(Palette.textPrimary)

                weekdayHeader

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(daysGrid, id: \.self) { day in
                        if let day {
                            dayCell(day)
                        } else {
                            Color.clear.frame(height: 30)
                        }
                    }
                }

                legend
            }
        }
    }

    private var weekdayHeader: some View {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let ordered = Array(symbols[1...]) + [symbols[0]]
        return HStack {
            ForEach(ordered, id: \.self) { symbol in
                Text(symbol)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var daysGrid: [Date?] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7

        var result: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                result.append(date)
            }
        }
        return result
    }

    private func dayCell(_ date: Date) -> some View {
        let calendar = Calendar.current
        let event = events.first { calendar.isDate($0.scheduledDate, inSameDayAs: date) }
        return VStack(spacing: 3) {
            Text("\(calendar.component(.day, from: date))")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(calendar.isDateInToday(date) ? .white : Palette.textPrimary)
                .frame(width: 22, height: 22)
                .background(calendar.isDateInToday(date) ? Palette.primary : Color.clear)
                .clipShape(Circle())
            dot(for: event?.status)
        }
        .frame(height: 34)
    }

    @ViewBuilder
    private func dot(for status: DoseStatus?) -> some View {
        switch status {
        case .takenOnTime, .placebo:
            Circle().fill(Palette.success).frame(width: 6, height: 6)
        case .takenLate:
            Circle().fill(Palette.warning).frame(width: 6, height: 6)
        case .missed:
            Circle().fill(Palette.danger).frame(width: 6, height: 6)
        default:
            Circle().fill(Color.clear).frame(width: 6, height: 6)
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(color: Palette.success, key: "history.legend.taken")
            legendItem(color: Palette.warning, key: "history.legend.late")
            legendItem(color: Palette.danger, key: "history.legend.missed")
        }
        .font(Typography.caption)
        .foregroundStyle(Palette.textSecondary)
    }

    private func legendItem(color: Color, key: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(key)
        }
    }
}
