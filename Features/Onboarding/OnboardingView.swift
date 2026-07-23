import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.services) private var services
    @Environment(\.modelContext) private var modelContext
    @Query private var preferencesList: [UserPreferences]

    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        Group {
            switch viewModel.step {
            case .intro:
                OnboardingIntroStep(onContinue: viewModel.goNext)
            case .pillSetup:
                OnboardingPillSetupStep(viewModel: viewModel, onContinue: viewModel.goNext, onBack: viewModel.goBack)
            case .notifications:
                OnboardingNotificationsStep(viewModel: viewModel, services: services, onContinue: viewModel.goNext, onBack: viewModel.goBack)
            case .privacy:
                OnboardingPrivacyStep(
                    viewModel: viewModel,
                    isBiometricAvailable: services?.biometricLock.isBiometricAvailable ?? false,
                    onFinish: finishOnboarding,
                    onBack: viewModel.goBack
                )
            }
        }
        .animation(.easeInOut, value: viewModel.step)
    }

    private func finishOnboarding() {
        guard let services else { return }
        let preferences = preferencesList.first ?? {
            let created = UserPreferences()
            modelContext.insert(created)
            return created
        }()
        viewModel.complete(services: services, context: modelContext, userPreferences: preferences)
    }
}

#Preview {
    OnboardingView()
        .modelContainer(PersistenceController.preview())
}
