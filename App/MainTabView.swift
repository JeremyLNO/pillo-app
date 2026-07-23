import SwiftUI

private enum Tab: Hashable {
    case home, blister, missedPill, history, settings
}

struct MainTabView: View {
    @Environment(\.services) private var services
    @State private var selection: Tab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label(String(localized: "tab.home"), systemImage: "house.fill") }
                .tag(Tab.home)

            BlisterPackView()
                .tabItem { Label(String(localized: "tab.blister"), systemImage: "square.grid.3x3.fill") }
                .tag(Tab.blister)

            MissedPillView()
                .tabItem { Label(String(localized: "tab.missedPill"), systemImage: "bell.badge.fill") }
                .tag(Tab.missedPill)

            HistoryView()
                .tabItem { Label(String(localized: "tab.history"), systemImage: "chart.bar.fill") }
                .tag(Tab.history)

            SettingsView()
                .tabItem { Label(String(localized: "tab.settings"), systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(Palette.primary)
        .onChange(of: services?.deepLinkRouter.pendingRoute) { _, newRoute in
            guard let newRoute else { return }
            switch newRoute {
            case .home, .today: selection = .home
            case .history: selection = .history
            case .settings, .update: selection = .settings
            case .missedPill: selection = .missedPill
            case .support: break // opened externally by DeepLinkRouter, no tab switch needed
            }
            services?.deepLinkRouter.pendingRoute = nil
        }
    }
}
