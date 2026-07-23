import Foundation

/// Shared between the iOS app and the iOS widget extension only — watchOS has its own,
/// physically separate local App Group (same identifier string, different device), never
/// synced through this one. See `Shared/WatchSnapshot.swift` for the watch-side path.
enum AppGroup {
    static let identifier = "group.company.lno.pillo"
}
