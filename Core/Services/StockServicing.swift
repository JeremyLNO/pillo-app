import Foundation
import SwiftData
import UserNotifications

@MainActor
protocol StockServicing {
    func currentStock() throws -> StockEntry
    func isLowStock(_ entry: StockEntry) -> Bool
    func decrementPack() throws
    /// Calendar date the current stock is projected to run out, assuming one pill/day.
    func estimatedDepletionDate(for entry: StockEntry) -> Date
    /// Schedules (or cancels) a single local "renew your prescription" reminder once
    /// stock crosses `lowStockThreshold`. Idempotent — safe to call on every stock edit.
    func syncLowStockReminder(for entry: StockEntry) async
}

@MainActor
final class StockService: StockServicing {
    private static let lowStockNotificationID = "pillo.lowStockReminder"
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func currentStock() throws -> StockEntry {
        let descriptor = FetchDescriptor<StockEntry>()
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let created = StockEntry()
        context.insert(created)
        try context.save()
        return created
    }

    func isLowStock(_ entry: StockEntry) -> Bool {
        entry.remainingPacks <= entry.lowStockThreshold
    }

    func decrementPack() throws {
        let entry = try currentStock()
        entry.remainingPacks = max(0, entry.remainingPacks - 1)
        entry.lastUpdatedAt = .now
        try context.save()
    }

    func estimatedDepletionDate(for entry: StockEntry) -> Date {
        let totalPills = entry.remainingPacks * entry.pillsPerPack
        return Calendar.current.date(byAdding: .day, value: totalPills, to: .now) ?? .now
    }

    func syncLowStockReminder(for entry: StockEntry) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.lowStockNotificationID])

        guard entry.renewalReminderEnabled, isLowStock(entry) else { return }
        let alreadyAuthorized = await center.notificationSettings().authorizationStatus == .authorized
        let justGranted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) == true
        guard alreadyAuthorized || justGranted else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "notification.reminder.title")
        content.body = String(localized: "stock.lowStockNotification.body")
        content.sound = .default

        // Fire the next morning rather than instantly — a low-stock edit is usually made
        // right before bed after confirming the last dose in a pack.
        var trigger = DateComponents()
        trigger.hour = 10
        let calendarTrigger = UNCalendarNotificationTrigger(dateMatching: trigger, repeats: false)
        let request = UNNotificationRequest(identifier: Self.lowStockNotificationID, content: content, trigger: calendarTrigger)
        try? await center.add(request)
    }
}
