import Foundation
import LocalAuthentication
import Observation

@Observable
@MainActor
final class BiometricLockService: BiometricLockServicing {
    private(set) var isLocked = false
    /// How long the app can stay backgrounded before the next foreground requires unlock.
    /// Not yet a user-configurable `UserPreferences` field in Phase 1 — a sensible fixed
    /// default (spec section 23 calls for "a configurable duration"; the Settings row for
    /// that lands alongside the rest of the Confidentialité polish in a later phase).
    var autoLockGracePeriod: TimeInterval = 15

    private var backgroundedAt: Date?

    var isBiometricAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    func noteDidEnterBackground() {
        backgroundedAt = .now
    }

    func noteWillEnterForeground(biometricLockEnabled: Bool) {
        defer { backgroundedAt = nil }
        guard biometricLockEnabled else { return }
        guard let backgroundedAt else { return }
        if Date.now.timeIntervalSince(backgroundedAt) >= autoLockGracePeriod {
            isLocked = true
        }
    }

    @discardableResult
    func authenticate() async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No biometrics/passcode configured on this device — don't strand the user
            // behind a lock screen they can never pass.
            isLocked = false
            return true
        }
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: String(localized: "security.faceid.reason")
            )
            if success { isLocked = false }
            return success
        } catch {
            return false
        }
    }

    func unlockWithPIN() {
        isLocked = false
    }
}
