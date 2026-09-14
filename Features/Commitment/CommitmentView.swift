import SwiftUI

/// Shown exactly once, before onboarding even starts (gated by
/// `UserPreferences.hasSeenCommitmentScreen`, independent of `completedOnboarding` so it's
/// never re-shown once seen). Explains that Pillo is free thanks to CrazyBeeLabs's
/// commitment across its app family (Cycles, Pillo, Respire) — a trust/brand statement,
/// not a configuration step, which is why it lives outside `OnboardingViewModel`'s flow.
struct CommitmentView: View {
    let configuration: AppConfiguration
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .fill(Palette.accentPink.opacity(0.15))
                        .frame(width: 84, height: 84)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Palette.accentPink)
                }

                VStack(spacing: 10) {
                    Text("commitment.title")
                        .font(Typography.largeTitle)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Palette.textPrimary)
                    Text("commitment.intro")
                        .font(Typography.headline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Palette.primaryDeep)
                }

                Card {
                    Text("commitment.body")
                        .font(Typography.body)
                        .foregroundStyle(Palette.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                PrimaryButton(title: String(localized: "onboarding.continue")) {
                    onContinue()
                }

                commitmentFooter
                otherAppsLink
                    .frame(maxWidth: .infinity)
            }
            .padding(28)
        }
        .background(Palette.background)
    }

    private var commitmentFooter: some View {
        Link(destination: configuration.crazyBeeCommitmentURL) {
            VStack(spacing: 10) {
                Image("CrazyBeeLabsLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                Text("commitment.footer.tagline")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
                Text("commitment.footer.link")
                    .font(Typography.caption.bold())
                    .foregroundStyle(Palette.primary)
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("commitment.footer.accessibilityLabel"))
    }

    /// Second destination, distinct from the commitment link above: this screen says the app
    /// belongs to a family of free apps, so it should also show where to find them.
    private var otherAppsLink: some View {
        Link(destination: configuration.crazyBeeAppsURL) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.2x2.fill")
                Text("commitment.footer.otherApps")
                Image(systemName: "arrow.up.right")
                    .font(.caption2.weight(.bold))
            }
            .font(Typography.caption.bold())
            .foregroundStyle(Palette.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.primary.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.top, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("commitment.footer.otherApps.accessibilityLabel"))
    }
}

#Preview {
    CommitmentView(configuration: .current, onContinue: {})
}
