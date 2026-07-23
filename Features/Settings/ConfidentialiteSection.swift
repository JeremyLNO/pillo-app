import SwiftUI
import SwiftData

struct ConfidentialiteSection: View {
    @Bindable var userPreferences: UserPreferences
    let isBiometricAvailable: Bool
    let configuration: AppConfiguration
    let appLock: AppLockServicing
    let dataExport: DataExportServicing
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirmation = false
    @State private var showPINSheet = false
    @State private var exportURL: URL?
    @State private var exportError = false

    var body: some View {
        Section(String(localized: "settings.privacy.title")) {
            if isBiometricAvailable {
                Toggle(String(localized: "settings.privacy.biometric"), isOn: $userPreferences.biometricLockEnabled)
            }
            Toggle(String(localized: "settings.privacy.discreetMode"), isOn: $userPreferences.discreetModeEnabled)

            if let exportURL {
                ShareLink(item: exportURL) {
                    Text("settings.privacy.export.share")
                }
            } else {
                Button {
                    do {
                        exportURL = try dataExport.exportAllData()
                    } catch {
                        exportError = true
                    }
                } label: {
                    Text("settings.privacy.export")
                }
                .alert(String(localized: "settings.privacy.export.error"), isPresented: $exportError) {
                    Button(String(localized: "common.ok"), role: .cancel) {}
                }
            }

            Button {
                showPINSheet = true
            } label: {
                HStack {
                    Text("settings.privacy.pin")
                        .foregroundStyle(Palette.textPrimary)
                    Spacer()
                    Text(appLock.isPINSet ? String(localized: "settings.privacy.pin.enabled") : String(localized: "settings.privacy.pin.disabled"))
                        .foregroundStyle(Palette.textSecondary)
                        .font(Typography.caption)
                }
            }
            .sheet(isPresented: $showPINSheet) {
                PINSetupSheet(appLock: appLock) { showPINSheet = false }
            }

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Text("settings.privacy.deleteAllData")
            }
            .confirmationDialog(
                Text("settings.privacy.deleteAllData.confirm"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(localized: "settings.privacy.deleteAllData.confirmButton"), role: .destructive) {
                    deleteAllData()
                }
                Button(String(localized: "common.cancel"), role: .cancel) {}
            }

            Link(String(localized: "settings.privacy.privacyPolicy"), destination: configuration.privacyPolicyURL)
            Link(String(localized: "settings.privacy.terms"), destination: configuration.termsURL)
        }
    }

    private func deleteAllData() {
        try? modelContext.delete(model: PillProfile.self)
        try? modelContext.delete(model: DoseEvent.self)
        try? modelContext.delete(model: SymptomEntry.self)
        try? modelContext.delete(model: StockEntry.self)
        try? modelContext.delete(model: CustomScheduleDay.self)
        try? modelContext.save()
        appLock.removePIN()
        userPreferences.completedOnboarding = false
    }
}
