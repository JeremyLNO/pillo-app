import XCTest
@testable import Pillo

final class LanguageResolverTests: XCTestCase {
    func testExplicitOverrideWinsOverSystemLanguage() {
        let result = LanguageResolver.resolve(
            hasExplicitOverride: true,
            selectedLanguage: "de",
            preferredLanguages: ["fr-FR", "en-US"]
        )
        XCTAssertEqual(result, .de)
    }

    func testSystemLanguageUsedWhenNoOverride() {
        let result = LanguageResolver.resolve(
            hasExplicitOverride: false,
            selectedLanguage: nil,
            preferredLanguages: ["es-ES", "en-US"]
        )
        XCTAssertEqual(result, .es)
    }

    func testFallsBackToEnglishWhenSystemLanguageUnsupported() {
        // Japanese isn't in AppLanguage's five supported languages.
        let result = LanguageResolver.resolve(
            hasExplicitOverride: false,
            selectedLanguage: nil,
            preferredLanguages: ["ja-JP"]
        )
        XCTAssertEqual(result, .en)
    }

    func testSkipsUnsupportedLanguagesToFindASupportedOne() {
        let result = LanguageResolver.resolve(
            hasExplicitOverride: false,
            selectedLanguage: nil,
            preferredLanguages: ["ja-JP", "pt-PT", "en-US"]
        )
        XCTAssertEqual(result, .pt)
    }

    func testOverrideFlagWithoutStoredLanguageFallsBackToSystem() {
        // Defensive case: hasExplicitOverride is true but selectedLanguage is somehow nil.
        let result = LanguageResolver.resolve(
            hasExplicitOverride: true,
            selectedLanguage: nil,
            preferredLanguages: ["fr-FR"]
        )
        XCTAssertEqual(result, .fr)
    }
}
