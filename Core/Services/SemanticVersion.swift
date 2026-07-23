import Foundation

/// Minimal, robust SemVer comparison for "x.y.z" (or "x.y"/"x") version strings — used
/// by the update-availability check (spec section 11) to compare the running app's
/// `CFBundleShortVersionString` against a remote `latestVersion`/`minimumSupportedVersion`.
struct SemanticVersion: Comparable, Sendable {
    let components: [Int]

    init?(_ string: String) {
        let parts = string.split(separator: ".").map { $0.trimmingCharacters(in: .whitespaces) }
        guard !parts.isEmpty else { return nil }
        var parsed: [Int] = []
        for part in parts {
            // Tolerate a trailing pre-release/build suffix like "1.4.0-beta1" by only
            // reading the leading digits of each dot-separated component.
            let digits = part.prefix { $0.isNumber }
            guard let value = Int(digits) else { return nil }
            parsed.append(value)
        }
        components = parsed
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let maxCount = max(lhs.components.count, rhs.components.count)
        for i in 0..<maxCount {
            let l = i < lhs.components.count ? lhs.components[i] : 0
            let r = i < rhs.components.count ? rhs.components[i] : 0
            if l != r { return l < r }
        }
        return false
    }

    static func == (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        let maxCount = max(lhs.components.count, rhs.components.count)
        for i in 0..<maxCount {
            let l = i < lhs.components.count ? lhs.components[i] : 0
            let r = i < rhs.components.count ? rhs.components[i] : 0
            if l != r { return false }
        }
        return true
    }
}
