import Foundation
import WatchConnectivity
import WidgetKit
import Observation

/// Receives `WidgetSnapshot` updates pushed from the paired iPhone via
/// `WCSession.updateApplicationContext` (see `Core/Services/WatchConnectivityService.swift`
/// on the phone side), persists them to the Watch's own local App Group (physically
/// separate storage from the phone's — same suite name, different device), and reloads
/// the complication timelines. Read-only by design (complications-only scope): this app
/// never writes back to the phone.
@Observable
@MainActor
final class WatchSessionReceiver: NSObject {
    private(set) var snapshot: WidgetSnapshot = WidgetSnapshotStore.read()

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
}

extension WatchSessionReceiver: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["snapshot"] as? Data,
              let decoded = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return }
        Task { @MainActor in
            WidgetSnapshotStore.write(decoded)
            self.snapshot = decoded
        }
    }
}
