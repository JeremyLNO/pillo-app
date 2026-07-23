import SwiftUI

struct TodayDoseCard: View {
    let event: DoseEvent?
    let profile: PillProfile
    let discreetMode: Bool
    let onConfirm: () -> Void
    let onUndo: () -> Void
    let onSnooze: () -> Void
    let onMissed: () -> Void
    let canSnooze: Bool

    private var isConfirmed: Bool {
        event?.actualTakenDate != nil
    }

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                Text(discreetMode ? "home.todayCard.title.discreet" : "home.todayCard.title")
                    .font(Typography.headline)
                    .foregroundStyle(Palette.textSecondary)

                if let event {
                    Text(event.scheduledTime, style: .time)
                        .font(Typography.clock)
                        .foregroundStyle(Palette.textPrimary)

                    statusBadge(for: event)

                    if isConfirmed {
                        HStack {
                            PrimaryButton(title: String(localized: "home.todayCard.confirmed"), systemImage: "checkmark.circle.fill", action: {})
                                .disabled(true)
                            Button(String(localized: "home.todayCard.undo"), action: onUndo)
                                .font(Typography.caption)
                        }
                    } else {
                        PrimaryButton(title: String(localized: "home.todayCard.confirm"), systemImage: "checkmark.circle.fill", action: onConfirm)
                        HStack(spacing: 12) {
                            SecondaryButton(title: String(localized: "home.todayCard.snooze"), systemImage: "clock", action: onSnooze)
                                .disabled(!canSnooze)
                                .opacity(canSnooze ? 1 : 0.4)
                            SecondaryButton(title: String(localized: "home.todayCard.missed"), systemImage: "questionmark.circle", action: onMissed)
                        }
                    }
                } else {
                    Text("home.todayCard.noneToday")
                        .font(Typography.body)
                        .foregroundStyle(Palette.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func statusBadge(for event: DoseEvent) -> some View {
        let now = Date.now
        if isConfirmed {
            EmptyView()
        } else if event.scheduledDateTime > now {
            let minutes = max(0, Int(event.scheduledDateTime.timeIntervalSince(now) / 60))
            badge(text: String(format: String(localized: "home.todayCard.dueIn"), minutes), color: Palette.warning, icon: "clock.fill")
        } else {
            let minutes = max(0, Int(now.timeIntervalSince(event.scheduledDateTime) / 60))
            badge(text: String(format: String(localized: "home.todayCard.overdue"), minutes), color: Palette.danger, icon: "exclamationmark.triangle.fill")
        }
    }

    private func badge(text: String, color: Color, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(Typography.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
