import Foundation

@MainActor
protocol BiometricLockServicing: AnyObject {
    var isLocked: Bool { get }
    var isBiometricAvailable: Bool { get }

    /// Called when the scene enters background — starts the auto-lock grace period.
    func noteDidEnterBackground()

    /// Called when the scene becomes active again — locks if the grace period elapsed.
    func noteWillEnterForeground(biometricLockEnabled: Bool)

    /// Prompts Face ID/Touch ID (falling back to device passcode). Returns whether unlock succeeded.
    @discardableResult
    func authenticate() async -> Bool

    /// Clears the lock after a successful PIN entry (`AppLockServicing.verifyPIN`) — a
    /// separate unlock path from Face ID, per spec section 20's independent PIN row.
    func unlockWithPIN()
}
