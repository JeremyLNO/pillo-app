import Foundation

/// OneSignal is used exclusively for CrazyBeeLabs announcements, update-availability
/// pushes, and communications the user explicitly opted into (spec section 10) — never
/// for the core pill reminder, which stays 100% local (`LocalNotificationServicing`).
@MainActor
protocol OneSignalServicing: AnyObject {
    /// No-ops if `appId` is empty/a placeholder — the app must stay fully functional
    /// with OneSignal absent or unconfigured.
    func initialize(appId: String)

    /// Prompts the system push-permission dialog. Safe to call even if the user already
    /// granted/denied local-notification permission — these are tracked separately per
    /// spec section 10 ("séparer clairement autorisation système / rappels locaux /
    /// notifications de mise à jour / communications facultatives").
    func requestPushPermissionIfNeeded() async

    /// Syncs only the technical tags the spec allows (section 10): app version,
    /// language, platform, build environment, and the user's consent flags. Never
    /// called with anything pill/health/contraception-related.
    func syncTechnicalTags(
        appVersion: String,
        language: String,
        environment: String,
        updateNotificationsConsent: Bool,
        marketingConsent: Bool
    )
}
