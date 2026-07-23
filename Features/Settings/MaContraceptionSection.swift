import SwiftUI

struct MaContraceptionSection: View {
    @Bindable var profile: PillProfile

    var body: some View {
        Section(String(localized: "settings.contraception.title")) {
            NavigationLink {
                Form {
                    TextField(String(localized: "onboarding.pillSetup.displayName"), text: $profile.displayName)
                    Picker(String(localized: "settings.contraception.pillType"), selection: Binding(
                        get: { profile.pillType },
                        set: { profile.pillType = $0 }
                    )) {
                        Text("pillType.combined").tag(PillType.combined)
                        Text("pillType.progestinOnly").tag(PillType.progestinOnly)
                        Text("pillType.other").tag(PillType.other)
                    }
                }
                .navigationTitle(Text("settings.contraception.editPill"))
            } label: {
                settingsRow(String(localized: "settings.contraception.editPill"), value: profile.displayName)
            }

            NavigationLink {
                Form {
                    Stepper(value: $profile.activePillCount, in: 1...99) {
                        Text(String(format: String(localized: "settings.contraception.activeCount"), profile.activePillCount))
                    }
                    Stepper(value: $profile.placeboPillCount, in: 0...14) {
                        Text(String(format: String(localized: "settings.contraception.placeboCount"), profile.placeboPillCount))
                    }
                }
                .navigationTitle(Text("settings.contraception.editBlister"))
            } label: {
                settingsRow(String(localized: "settings.contraception.editBlister"), value: "\(profile.activePillCount + profile.placeboPillCount) j")
            }

            NavigationLink {
                Form {
                    DatePicker(String(localized: "onboarding.pillSetup.usualIntakeTime"), selection: $profile.usualIntakeTime, displayedComponents: .hourAndMinute)
                }
                .navigationTitle(Text("settings.contraception.editTime"))
            } label: {
                settingsRow(String(localized: "settings.contraception.editTime"), value: profile.usualIntakeTime.formatted(date: .omitted, time: .shortened))
            }

            NavigationLink {
                Form {
                    DatePicker(String(localized: "onboarding.pillSetup.startDate"), selection: $profile.startDate, displayedComponents: .date)
                }
                .navigationTitle(Text("settings.contraception.editStartDate"))
            } label: {
                settingsRow(String(localized: "settings.contraception.editStartDate"), value: profile.startDate.formatted(date: .abbreviated, time: .omitted))
            }
        }
    }

    private func settingsRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(Palette.textSecondary)
        }
    }
}
