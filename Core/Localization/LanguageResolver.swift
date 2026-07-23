import Foundation

/// Pure resolution logic, extracted from `LocalizationService` so the fallback priority
/// (explicit override > system language > English) is unit-testable without depending on
/// the live `Locale.preferredLanguages` the test happens to run under.
enum LanguageResolver {
    static func resolve(
        hasExplicitOverride: Bool,
        selectedLanguage: String?,
        preferredLanguages: [String]
    ) -> AppLanguage {
        if hasExplicitOverride, let raw = selectedLanguage, let explicit = AppLanguage(rawValue: raw) {
            return explicit
        }
        for identifier in preferredLanguages {
            let languageCode = Locale(identifier: identifier).language.languageCode?.identifier
            if let languageCode, let match = AppLanguage(rawValue: languageCode) {
                return match
            }
        }
        return .en
    }
}
