import Foundation
import SwiftData

@Model
final class UserPreferences {
    @Attribute(.unique) var id: UUID
    /// nil means "follow system language" (hasExplicitLanguageOverride == false).
    var selectedLanguage: String?
    var hasExplicitLanguageOverride: Bool
    var biometricLockEnabled: Bool
    var discreetModeEnabled: Bool
    var installDate: Date
    var reviewRequestDate: Date?
    var reviewRequestAttempted: Bool
    var completedOnboarding: Bool
    var appearancePreferenceRaw: String
    /// Additive anchor field used to detect timezone/DST changes (spec section 16) —
    /// not in the spec's literal field list but required to implement it.
    var lastKnownTimeZoneIdentifier: String?
    /// Shown once ever, before onboarding — explains that Pillo is free thanks to
    /// CrazyBeeLabs's commitment. Independent of `completedOnboarding` so it's never
    /// re-shown even if onboarding itself is somehow re-entered.
    var hasSeenCommitmentScreen: Bool

    var appearancePreference: AppearancePreference {
        get { AppearancePreference(rawValue: appearancePreferenceRaw) ?? .system }
        set { appearancePreferenceRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        selectedLanguage: String? = nil,
        hasExplicitLanguageOverride: Bool = false,
        biometricLockEnabled: Bool = false,
        discreetModeEnabled: Bool = false,
        installDate: Date = .now,
        reviewRequestDate: Date? = nil,
        reviewRequestAttempted: Bool = false,
        completedOnboarding: Bool = false,
        appearancePreference: AppearancePreference = .system,
        lastKnownTimeZoneIdentifier: String? = nil,
        hasSeenCommitmentScreen: Bool = false
    ) {
        self.id = id
        self.selectedLanguage = selectedLanguage
        self.hasExplicitLanguageOverride = hasExplicitLanguageOverride
        self.biometricLockEnabled = biometricLockEnabled
        self.discreetModeEnabled = discreetModeEnabled
        self.installDate = installDate
        self.reviewRequestDate = reviewRequestDate
        self.reviewRequestAttempted = reviewRequestAttempted
        self.completedOnboarding = completedOnboarding
        self.appearancePreferenceRaw = appearancePreference.rawValue
        self.lastKnownTimeZoneIdentifier = lastKnownTimeZoneIdentifier
        self.hasSeenCommitmentScreen = hasSeenCommitmentScreen
    }
}
