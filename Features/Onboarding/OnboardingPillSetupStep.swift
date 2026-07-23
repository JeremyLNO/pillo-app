import SwiftUI

struct OnboardingPillSetupStep: View {
    @Bindable var viewModel: OnboardingViewModel
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var showingScan = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("onboarding.pillSetup.title")
                    .font(Typography.title)
                    .foregroundStyle(Palette.textPrimary)

                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        labeledField(String(localized: "onboarding.pillSetup.displayName")) {
                            TextField(String(localized: "onboarding.pillSetup.displayName.placeholder"), text: $viewModel.displayName)
                        }
                        Divider()
                        labeledField(String(localized: "onboarding.pillSetup.brandName")) {
                            TextField(String(localized: "onboarding.pillSetup.brandName.placeholder"), text: $viewModel.brandName)
                        }
                    }
                }

                SecondaryButton(title: String(localized: "onboarding.scan.cta")) {
                    showingScan = true
                }

                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("onboarding.pillSetup.scheduleType")
                            .font(Typography.headline)
                        Picker(String(localized: "onboarding.pillSetup.scheduleType"), selection: $viewModel.scheduleType) {
                            Text("scheduleType.days21Active7Stop").tag(ScheduleType.days21Active7Stop)
                            Text("scheduleType.days24Active4Placebo").tag(ScheduleType.days24Active4Placebo)
                            Text("scheduleType.days28").tag(ScheduleType.days28)
                            Text("scheduleType.continuous").tag(ScheduleType.continuous)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: viewModel.scheduleType) { _, newValue in applyDefaults(for: newValue) }

                        Stepper(value: $viewModel.activePillCount, in: 1...99) {
                            HStack {
                                Text("onboarding.pillSetup.activePillCount")
                                Spacer()
                                Text("\(viewModel.activePillCount)").foregroundStyle(Palette.textSecondary)
                            }
                        }
                        if viewModel.scheduleType != .continuous {
                            Stepper(value: $viewModel.placeboPillCount, in: 0...14) {
                                HStack {
                                    Text("onboarding.pillSetup.placeboPillCount")
                                    Spacer()
                                    Text("\(viewModel.placeboPillCount)").foregroundStyle(Palette.textSecondary)
                                }
                            }
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        DatePicker(String(localized: "onboarding.pillSetup.usualIntakeTime"), selection: $viewModel.usualIntakeTime, displayedComponents: .hourAndMinute)
                        DatePicker(String(localized: "onboarding.pillSetup.startDate"), selection: $viewModel.startDate, displayedComponents: .date)
                        Stepper(value: $viewModel.allowedDelayMinutes, in: 0...1440, step: 30) {
                            HStack {
                                Text("onboarding.pillSetup.allowedDelay")
                                Spacer()
                                Text("\(viewModel.allowedDelayMinutes / 60) h").foregroundStyle(Palette.textSecondary)
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    SecondaryButton(title: String(localized: "onboarding.back")) { onBack() }
                    PrimaryButton(title: String(localized: "onboarding.continue")) { onContinue() }
                        .disabled(!viewModel.canAdvanceFromPillSetup)
                        .opacity(viewModel.canAdvanceFromPillSetup ? 1 : 0.5)
                }
            }
            .padding(24)
        }
        .background(Palette.background)
        .sheet(isPresented: $showingScan) {
            BlisterScanSheet { result in
                viewModel.scheduleType = result.scheduleType
                viewModel.activePillCount = result.activePillCount
                viewModel.placeboPillCount = result.placeboPillCount
            }
        }
    }

    private func applyDefaults(for scheduleType: ScheduleType) {
        switch scheduleType {
        case .days21Active7Stop:
            viewModel.activePillCount = 21
            viewModel.placeboPillCount = 7
        case .days24Active4Placebo:
            viewModel.activePillCount = 24
            viewModel.placeboPillCount = 4
        case .days28:
            viewModel.activePillCount = 28
            viewModel.placeboPillCount = 0
        case .continuous:
            viewModel.activePillCount = 28
            viewModel.placeboPillCount = 0
        case .custom:
            break
        }
    }

    private func labeledField(_ label: String, @ViewBuilder field: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Palette.textSecondary)
            field()
                .font(Typography.body)
        }
    }
}
