import SwiftUI

/// Read-only mirror of the phone's "next dose" card — no confirm action here by design
/// (complications-only scope: the Watch app is a minimal companion, not a second place to
/// manage doses). Uses plain system colors/fonts rather than the shared `Palette`, which
/// depends on `UIColor` (UIKit, unavailable on watchOS).
struct WatchHomeView: View {
    let receiver: WatchSessionReceiver

    private var snapshot: WidgetSnapshot { receiver.snapshot }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if !snapshot.hasActiveProfile {
                    Image(systemName: "pills.fill")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    Text("watch.onboardingPrompt")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                } else {
                    Text(snapshot.discreetMode ? "watch.title.discreet" : "watch.title")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let date = snapshot.nextDoseDate {
                        Text(date, style: .time)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        if snapshot.nextDoseIsConfirmed {
                            Label(String(localized: "widget.confirmed"), systemImage: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        } else {
                            Text(date, style: .relative)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("widget.noneToday")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    HStack(spacing: 16) {
                        VStack {
                            Image(systemName: "flame.fill").foregroundStyle(.orange)
                            Text("\(snapshot.streakDays)").font(.caption.bold())
                        }
                        VStack {
                            Image(systemName: "number").foregroundStyle(.purple)
                            Text("\(snapshot.dayInPack)/\(snapshot.packSize)").font(.caption.bold())
                        }
                        VStack {
                            Image(systemName: "checkmark.shield.fill").foregroundStyle(.green)
                            Text("\(snapshot.observancePercent)%").font(.caption.bold())
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Pillo tracker")
    }
}

#Preview {
    WatchHomeView(receiver: WatchSessionReceiver())
}
