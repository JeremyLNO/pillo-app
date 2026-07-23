import SwiftUI

struct HomeStatTilesView: View {
    let streakDays: Int
    let observancePercent: Int
    let remainingPacks: Int

    var body: some View {
        HStack(spacing: 12) {
            StatTile(systemImage: "flame.fill", iconColor: Palette.warning, title: String(localized: "home.stats.streak"), value: "\(streakDays)", unit: String(localized: "home.stats.days"))
            StatTile(systemImage: "checkmark.shield.fill", iconColor: Palette.success, title: String(localized: "home.stats.observance"), value: "\(observancePercent)", unit: "%")
            StatTile(systemImage: "pills.fill", iconColor: Palette.primary, title: String(localized: "home.stats.stock"), value: "\(remainingPacks)", unit: String(localized: "home.stats.packs"))
        }
    }
}
