import SwiftUI

struct OnboardingNotificationsStep: View {
    @Bindable var viewModel: OnboardingViewModel
    let services: ServiceContainer?
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56))
                .foregroundStyle(Palette.primary)

            Text("onboarding.notifications.title")
                .font(Typography.title)
                .multilineTextAlignment(.center)

            Text("onboarding.notifications.message")
                .font(Typography.body)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)

            Text("onboarding.notifications.usableWithout")
                .font(Typography.caption)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            if viewModel.didRequestNotifications {
                Label(
                    viewModel.notificationsAuthorized
                        ? String(localized: "onboarding.notifications.granted")
                        : String(localized: "onboarding.notifications.denied"),
                    systemImage: viewModel.notificationsAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .foregroundStyle(viewModel.notificationsAuthorized ? Palette.success : Palette.warning)
            }

            HStack(spacing: 12) {
                SecondaryButton(title: String(localized: "onboarding.back")) { onBack() }
                PrimaryButton(title: viewModel.didRequestNotifications ? String(localized: "onboarding.continue") : String(localized: "onboarding.notifications.enable")) {
                    if viewModel.didRequestNotifications {
                        onContinue()
                    } else if let services {
                        Task {
                            await viewModel.requestNotificationPermission(services: services)
                        }
                    }
                }
            }
        }
        .padding(28)
        .background(Palette.background)
    }
}
