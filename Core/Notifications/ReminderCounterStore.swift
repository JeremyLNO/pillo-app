import Foundation

/// Tracks how many follow-up reminders have actually fired for a given dose, so the UI
/// can stop offering "Reporter" once `maximumReminderCount` is reached. Deliberately
/// transient (UserDefaults, not a `DoseEvent` field) — it's a UI nicety, not medical
/// history, and doesn't belong in the persisted schema.
@MainActor
final class ReminderCounterStore {
    private let defaults: UserDefaults
    private let keyPrefix = "pillo.reminderCount."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func count(for doseEventID: UUID) -> Int {
        defaults.integer(forKey: keyPrefix + doseEventID.uuidString)
    }

    func increment(for doseEventID: UUID) {
        let key = keyPrefix + doseEventID.uuidString
        defaults.set(defaults.integer(forKey: key) + 1, forKey: key)
    }

    func reset(for doseEventID: UUID) {
        defaults.removeObject(forKey: keyPrefix + doseEventID.uuidString)
    }
}
