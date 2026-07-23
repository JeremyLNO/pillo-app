import Foundation

/// Validates any URL that originates from an external, untrusted source (a OneSignal
/// push payload, a remote-config JSON file) before the app is allowed to open it —
/// spec section 11: "Valider toutes les URL avant ouverture et refuser les schémas non
/// autorisés." Never used for URLs the user typed or that ship hardcoded in
/// `AppConfiguration` — only for values that arrived over the network.
enum URLValidator {
    private static let allowedHTTPSHosts: Set<String> = [
        "crazybeelabs.com",
        "apps.apple.com",
        "itunes.apple.com",
    ]

    static func isAllowed(_ url: URL) -> Bool {
        switch url.scheme?.lowercased() {
        case "pillo":
            return true
        case "https":
            guard let host = url.host?.lowercased() else { return false }
            return allowedHTTPSHosts.contains(host) || allowedHTTPSHosts.contains { host.hasSuffix("." + $0) }
        default:
            return false
        }
    }

    /// Parses and validates in one step; returns nil for malformed or disallowed URLs.
    static func validated(_ string: String?) -> URL? {
        guard let string, let url = URL(string: string), isAllowed(url) else { return nil }
        return url
    }
}
