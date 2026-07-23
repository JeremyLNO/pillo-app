import Foundation

/// Posted by `DoseTrackingService` after every mutation. Kept as a plain
/// `NotificationCenter` name (not a direct call into `WidgetBridge`/`WatchConnectivityService`)
/// so `DoseTrackingService` — compiled into the widget extension too — never needs to
/// know about `PillScheduleCalculator` or `WatchConnectivity`, both app-only.
enum DoseChangeNotifying {
    static let name = Notification.Name("company.lno.pillo.doseDidChange")
}
