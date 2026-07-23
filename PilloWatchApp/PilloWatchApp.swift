import SwiftUI

@main
struct PilloWatchApp: App {
    @State private var receiver = WatchSessionReceiver()

    var body: some Scene {
        WindowGroup {
            WatchHomeView(receiver: receiver)
        }
    }
}
