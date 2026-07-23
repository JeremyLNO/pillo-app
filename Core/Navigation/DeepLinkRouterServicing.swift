import Foundation
import UIKit
import Observation

@MainActor
protocol DeepLinkRouterServicing: AnyObject {
    var pendingRoute: Route? { get set }
    func handle(url: URL)
}

/// Resolves `pillo://` deep links (spec section 22): home/today, history, settings,
/// update, support, pill/missed. `support` and an external `action_url` open the system
/// browser directly rather than navigating in-app; everything else sets `pendingRoute`,
/// which `MainTabView` consumes on its next render. The biometric-lock-aware gating
/// (never bypass the lock via a deep link) lives in `RootView`, which queues the URL
/// while locked and only calls `handle(url:)` once unlocked.
@Observable
@MainActor
final class DeepLinkRouter: DeepLinkRouterServicing {
    var pendingRoute: Route?
    private let supportURL: URL

    init(supportURL: URL) {
        self.supportURL = supportURL
    }

    func handle(url: URL) {
        guard URLValidator.isAllowed(url) else { return }
        guard url.scheme == "pillo", let host = url.host else { return }
        switch host {
        case "home", "today":
            pendingRoute = .home
        case "history":
            pendingRoute = .history
        case "settings":
            pendingRoute = .settings
        case "update":
            pendingRoute = .update
        case "support":
            UIApplication.shared.open(supportURL)
        default:
            if url.path.contains("missed") {
                pendingRoute = .missedPill
            }
        }
    }
}
