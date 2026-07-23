import Foundation
import SwiftData
import Observation

/// Resolves the active app language and applies it immediately via the SwiftUI
/// `\.locale` environment (set by `RootView`), so switching language never requires
/// relaunching the app. Priority, per the spec: explicit user override > system language
/// (if supported) > English fallback.
@Observable
@MainActor
final class LocalizationService: LocalizationServicing {
    private(set) var currentLanguage: AppLanguage
    private let context: ModelContext
    private let preferences: UserPreferences

    init(context: ModelContext, preferences: UserPreferences) {
        self.context = context
        self.preferences = preferences
        self.currentLanguage = Self.resolve(preferences: preferences)
    }

    func setExplicitOverride(_ language: AppLanguage?) {
        if let language {
            preferences.selectedLanguage = language.rawValue
            preferences.hasExplicitLanguageOverride = true
            currentLanguage = language
        } else {
            preferences.selectedLanguage = nil
            preferences.hasExplicitLanguageOverride = false
            currentLanguage = Self.resolve(preferences: preferences)
        }
        try? context.save()
    }

    private static func resolve(preferences: UserPreferences) -> AppLanguage {
        LanguageResolver.resolve(
            hasExplicitOverride: preferences.hasExplicitLanguageOverride,
            selectedLanguage: preferences.selectedLanguage,
            preferredLanguages: Locale.preferredLanguages
        )
    }
}
