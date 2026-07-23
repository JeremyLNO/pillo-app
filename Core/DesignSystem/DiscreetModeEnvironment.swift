import SwiftUI

/// Separate concern from the biometric `LockGateView`: discreet mode swaps pill-specific
/// wording/icons for generic ones while the app is otherwise fully visible and unlocked.
private struct DiscreetModeKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var discreetModeEnabled: Bool {
        get { self[DiscreetModeKey.self] }
        set { self[DiscreetModeKey.self] = newValue }
    }
}
