import SwiftUI

struct LangueSection: View {
    @Bindable var userPreferences: UserPreferences
    let localization: LocalizationServicing

    var body: some View {
        Section(String(localized: "settings.language.title")) {
            Button {
                localization.setExplicitOverride(nil)
            } label: {
                row(title: String(localized: "settings.language.system"), isSelected: !userPreferences.hasExplicitLanguageOverride)
            }
            ForEach(AppLanguage.allCases) { language in
                Button {
                    localization.setExplicitOverride(language)
                } label: {
                    row(title: language.nativeName, isSelected: userPreferences.hasExplicitLanguageOverride && localization.currentLanguage == language)
                }
            }
        }
    }

    private func row(title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title).foregroundStyle(Palette.textPrimary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark").foregroundStyle(Palette.primary)
            }
        }
    }
}
