import SwiftUI

struct OnboardingPrivacyStep: View {
    @Bindable var viewModel: OnboardingViewModel
    let isBiometricAvailable: Bool
    let onFinish: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("onboarding.privacy.title")
                    .font(Typography.title)
                    .foregroundStyle(Palette.textPrimary)

                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        if isBiometricAvailable {
                            Toggle(isOn: $viewModel.biometricLockEnabled) {
                                Text("onboarding.privacy.biometricLock")
                            }
                        }
                        Toggle(isOn: $viewModel.discreetModeEnabled) {
                            Text("onboarding.privacy.discreetMode")
                        }
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("onboarding.privacy.customMessage")
                                .font(Typography.caption)
                                .foregroundStyle(Palette.textSecondary)
                            TextField(String(localized: "onboarding.privacy.customMessage.placeholder"), text: $viewModel.customReminderMessage)
                        }
                    }
                }

                HStack(spacing: 12) {
                    SecondaryButton(title: String(localized: "onboarding.back")) { onBack() }
                    PrimaryButton(title: String(localized: "onboarding.finish")) { onFinish() }
                }
            }
            .padding(24)
        }
        .background(Palette.background)
    }
}
