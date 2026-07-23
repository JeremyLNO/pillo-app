import Foundation

@MainActor
protocol LocalNotificationServicing {
    /// Requests notification authorization if not already determined. Returns whether
    /// reminders can actually be delivered (false if denied) — the app must stay fully
    /// usable either way.
    @discardableResult
    func requestAuthorizationIfNeeded() async -> Bool

    /// Diffs the desired sliding-window notification set for `profile` against what's
    /// currently pending and adds/removes only the delta. Safe to call repeatedly.
    func refreshSchedule(for profile: PillProfile, events: [DoseEvent], preferences: NotificationPreferences) async

    /// Cancels every pending reminder tied to one dose (called after confirm/undo/missed).
    func cancelReminders(for event: DoseEvent) async

    /// Cancels every pending reminder for a profile (called when a profile is deleted/deactivated).
    func cancelAllReminders(for profile: PillProfile) async
}
