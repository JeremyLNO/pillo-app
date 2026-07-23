import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.services) private var services
    @Query(filter: #Predicate<PillProfile> { $0.isActive }) private var profiles: [PillProfile]
    @Query private var notificationPreferencesList: [NotificationPreferences]
    @Query private var userPreferencesList: [UserPreferences]
    @Query private var stockEntries: [StockEntry]

    var body: some View {
        NavigationStack {
            Group {
                if let profile = profiles.first,
                   let preferences = notificationPreferencesList.first,
                   let userPreferences = userPreferencesList.first,
                   let stock = stockEntries.first,
                   let services {
                    Form {
                        MaContraceptionSection(profile: profile)
                        RappelsSection(preferences: preferences)
                        TrustedContactSection(preferences: preferences)
                        ConfidentialiteSection(
                            userPreferences: userPreferences,
                            isBiometricAvailable: services.biometricLock.isBiometricAvailable,
                            configuration: services.configuration,
                            appLock: services.appLock,
                            dataExport: services.dataExport
                        )
                        StockSection(stock: stock)
                        LangueSection(userPreferences: userPreferences, localization: services.localization)
                        NotificationsCrazyBeeLabsSection(
                            preferences: preferences,
                            oneSignal: services.oneSignal,
                            updateAvailability: services.updateAvailability
                        )
                        CrazyBeeLabsSection(configuration: services.configuration)

                        Section {
                            CrazyBeeLabsFooterView(websiteURL: services.configuration.crazyBeeWebsiteURL)
                                .listRowBackground(Color.clear)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(Text("tab.settings"))
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(PersistenceController.preview())
}
