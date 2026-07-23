import SwiftUI
import StoreKit

struct CrazyBeeLabsSection: View {
    let configuration: AppConfiguration

    var body: some View {
        Section(String(localized: "settings.crazybeelabs.title")) {
            AccountRowLink(url: configuration.crazyBeeAccountURL)
            Link(String(localized: "settings.crazybeelabs.support"), destination: configuration.crazyBeeSupportURL)
            Link(String(localized: "settings.crazybeelabs.rateApp"), destination: configuration.appStoreReviewURL)
            Link(String(localized: "settings.crazybeelabs.website"), destination: configuration.crazyBeeWebsiteURL)

            HStack {
                Text("settings.crazybeelabs.version")
                Spacer()
                Text(versionString)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
