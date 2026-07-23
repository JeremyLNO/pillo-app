import SwiftUI

struct OnboardingIntroStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            PilloWordmark(size: 44)

            VStack(alignment: .leading, spacing: 18) {
                bullet("bell.fill", "onboarding.intro.point.reminders")
                bullet("wifi.slash", "onboarding.intro.point.offline")
                bullet("heart.text.square.fill", "onboarding.intro.point.notMedical")
                bullet("person.crop.circle.badge.xmark", "onboarding.intro.point.noAccount")
            }
            .padding(.horizontal, 8)

            Spacer()
            PrimaryButton(title: String(localized: "onboarding.intro.continue")) {
                onContinue()
            }
        }
        .padding(28)
        .background(Palette.background)
    }

    private func bullet(_ systemImage: String, _ key: String.LocalizationValue) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .foregroundStyle(Palette.primary)
                .frame(width: 26)
            Text(String(localized: key))
                .font(Typography.body)
                .foregroundStyle(Palette.textPrimary)
        }
    }
}

#Preview {
    OnboardingIntroStep(onContinue: {})
}
