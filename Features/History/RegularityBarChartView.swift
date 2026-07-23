import SwiftUI
import Charts

struct RegularityBarChartView: View {
    struct DayPoint: Identifiable {
        let id = UUID()
        let date: Date
        let onTrack: Bool
        let hasEvent: Bool
    }

    let points: [DayPoint]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("history.regularity.title")
                    .font(Typography.headline)
                Text("history.regularity.subtitle")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)

                Chart(points) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Value", point.hasEvent ? (point.onTrack ? 100 : 40) : 0)
                    )
                    .foregroundStyle(point.hasEvent ? (point.onTrack ? Palette.success : Palette.warning) : Palette.textSecondary.opacity(0.2))
                    .cornerRadius(3)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.narrow))
                    }
                }
                .frame(height: 90)
            }
        }
    }
}
