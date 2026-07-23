import SwiftUI
import SwiftData

struct MissedPillView: View {
    @Environment(\.services) private var services
    @Query(filter: #Predicate<PillProfile> { $0.isActive }) private var profiles: [PillProfile]

    @State private var viewModel = MissedPillViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("missedpill.title")
                        .font(Typography.title)
                    Text("missedpill.subtitle")
                        .font(Typography.subheadline)
                        .foregroundStyle(Palette.textSecondary)

                    Card {
                        DelayButtonsView(selection: $viewModel.delayBucket)
                    }
                    Card {
                        PillCountStepperView(count: $viewModel.pillsMissed)
                    }
                    Card {
                        BlisterWeekSelectorView(selectedWeek: $viewModel.weekInPack)
                    }
                    Card {
                        Toggle(isOn: $viewModel.recentIntercourse) {
                            Label(String(localized: "missedpill.intercourse.question"), systemImage: "heart.circle")
                                .font(Typography.headline)
                        }
                    }

                    if let profile = profiles.first, let services {
                        let guidance = viewModel.guidance(pillType: profile.pillType, services: services)
                        switch guidance {
                        case .rule(let rule):
                            FallbackGuidanceCard(message: rule.recommendedActions.joined(separator: "\n"))
                        case .fallback(let message):
                            FallbackGuidanceCard(message: message)
                        }
                    }

                    ContactProfessionalButton()

                    Text("missedpill.disclaimer.notReplacement")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(16)
            }
            .background(Palette.background)
            .navigationTitle(Text("missedpill.navTitle"))
        }
    }
}

#Preview {
    MissedPillView()
        .modelContainer(PersistenceController.preview())
}
