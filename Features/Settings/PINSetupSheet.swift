import SwiftUI

struct PINSetupSheet: View {
    let appLock: AppLockServicing
    let onDone: () -> Void

    @State private var pin: String = ""
    @State private var confirmPin: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField(String(localized: "pin.setup.enter"), text: $pin)
                        .keyboardType(.numberPad)
                    SecureField(String(localized: "pin.setup.confirm"), text: $confirmPin)
                        .keyboardType(.numberPad)
                }
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(Palette.danger)
                        .font(Typography.caption)
                }
                if appLock.isPINSet {
                    Section {
                        Button(role: .destructive) {
                            appLock.removePIN()
                            onDone()
                        } label: {
                            Text("pin.setup.remove")
                        }
                    }
                }
            }
            .navigationTitle(Text("settings.privacy.pin"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel"), action: onDone)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save"), action: save)
                }
            }
        }
    }

    private func save() {
        guard pin.count >= 4, pin.allSatisfy(\.isNumber) else {
            errorMessage = String(localized: "pin.setup.errorLength")
            return
        }
        guard pin == confirmPin else {
            errorMessage = String(localized: "pin.setup.errorMismatch")
            return
        }
        appLock.setPIN(pin)
        onDone()
    }
}
