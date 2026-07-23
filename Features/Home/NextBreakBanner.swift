import SwiftUI

struct NextBreakBanner: View {
    /// nil means this schedule never pauses (28-pill / continuous) — shown as "next pack" instead.
    let nextBreakDate: Date?
    let nextPackStartDate: Date
    let placeboRangeText: String?

    var body: some View {
        Card(padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Palette.warning.opacity(0.18))
                    Image(systemName: "sunrise.fill").foregroundStyle(Palette.warning)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    if let nextBreakDate {
                        Text("home.nextBreak.title")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.textSecondary)
                        Text(daysUntilText(nextBreakDate))
                            .font(Typography.headline)
                            .foregroundStyle(Palette.warning)
                        if let placeboRangeText {
                            Text(placeboRangeText)
                                .font(Typography.caption)
                                .foregroundStyle(Palette.textSecondary)
                        }
                    } else {
                        Text("home.nextPack.title")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.textSecondary)
                        Text(daysUntilText(nextPackStartDate))
                            .font(Typography.headline)
                            .foregroundStyle(Palette.warning)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }

    private func daysUntilText(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: date)).day ?? 0
        if days <= 0 { return String(localized: "home.nextBreak.today") }
        return String(format: String(localized: "home.nextBreak.inDays"), days)
    }
}
