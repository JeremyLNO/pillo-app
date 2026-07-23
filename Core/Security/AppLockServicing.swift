import Foundation
import CryptoKit

/// A standalone PIN code, independent of Face ID/Touch ID (spec section 20's "Code PIN"
/// row is separate from "Face ID ou Touch ID"). Only the SHA-256 hash is persisted
/// (Keychain, `.afterFirstUnlockThisDeviceOnly`) — the PIN itself is never stored.
@MainActor
protocol AppLockServicing: AnyObject {
    var isPINSet: Bool { get }
    func setPIN(_ pin: String)
    func verifyPIN(_ pin: String) -> Bool
    func removePIN()
}

final class AppLockService: AppLockServicing {
    private let account = "pin-hash"

    var isPINSet: Bool {
        KeychainStore.get(account: account) != nil
    }

    func setPIN(_ pin: String) {
        KeychainStore.set(Self.hash(pin), account: account)
    }

    func verifyPIN(_ pin: String) -> Bool {
        guard let stored = KeychainStore.get(account: account) else { return false }
        return stored == Self.hash(pin)
    }

    func removePIN() {
        KeychainStore.remove(account: account)
    }

    private static func hash(_ pin: String) -> Data {
        Data(SHA256.hash(data: Data(pin.utf8)))
    }
}
