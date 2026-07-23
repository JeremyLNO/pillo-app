import Foundation

/// Internal destinations, mirroring the `pillo://` deep link scheme from the spec.
/// Phase 1 ships the router plumbing (needed so a tapped notification opens the right
/// tab) but not the full external URL-scheme/Universal Link wiring — that's a later phase.
enum Route: Equatable {
    case home
    case today
    case history
    case settings
    case missedPill
    case support
    case update
}
