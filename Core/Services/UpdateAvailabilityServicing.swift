import Foundation

struct UpdateCheckResult: Sendable, Equatable, Identifiable {
    let latestVersion: String
    let minimumSupportedVersion: String
    let appStoreURL: URL
    let message: String
    /// True when the running version is below `minimumSupportedVersion` — the app
    /// should block usage until updated. False when merely below `latestVersion`
    /// (optional update, shown as a dismissible banner, never as a hard block).
    let isMandatory: Bool

    var id: String { latestVersion + "-" + minimumSupportedVersion }
}

@MainActor
protocol UpdateAvailabilityServicing {
    /// Fetches and parses `REMOTE_CONFIG_URL`, comparing against the running app
    /// version. Returns nil if no update is needed, no URL is configured, the network
    /// is unavailable, or the payload fails validation — the app must never treat a
    /// failed check as "update required" (would strand offline users).
    func checkForUpdate() async -> UpdateCheckResult?
}

/// Mirrors the JSON shape from spec section 11 exactly.
struct RemoteUpdateConfig: Decodable {
    let latestVersion: String
    let minimumSupportedVersion: String
    let appStoreURL: String
    let message: [String: String]
}
