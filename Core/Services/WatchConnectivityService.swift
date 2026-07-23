import Foundation
import WatchConnectivity

/// Pushes the same `WidgetSnapshot` shape to a paired Apple Watch via
/// `updateApplicationContext` (always delivers the latest value even if the watch app
/// isn't running — exactly what a complication needs, as opposed to `sendMessage`, which
/// requires both sides reachable right now). No-ops gracefully on devices without a
/// paired Watch, in Simulator without Watch pairing, or if `WCSession` is unsupported.
@MainActor
protocol WatchConnectivityServicing {
    func activate()
    func send(_ snapshot: WidgetSnapshot)
}

@MainActor
final class WatchConnectivityService: NSObject, WatchConnectivityServicing {
    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    func activate() {
        guard let session, session.delegate == nil else { return }
        session.delegate = self
        session.activate()
    }

    func send(_ snapshot: WidgetSnapshot) {
        guard let session, session.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? session.updateApplicationContext(["snapshot": data])
    }
}

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
