import SwiftUI

/// Full-screen cover shown while `BiometricLockServicing.isLocked` is true. Also serves
/// as the app-switcher privacy cover: since it's part of the normal view hierarchy (not a
/// conditional overlay added only after backgrounding), the system's multitasking
/// snapshot captures this screen instead of any pill/health content whenever the app is
/// locked at the moment a snapshot is taken.
struct LockGateView: View {
    @Environment(\.services) private var services
    @State private var isAuthenticating = false
    @State private var showPINEntry = false
    @State private var pinInput = ""
    @State private var pinError = false

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Palette.primary)
                Text("lock.title")
                    .font(Typography.title)
                    .foregroundStyle(Palette.textPrimary)

                if showPINEntry {
                    SecureField(String(localized: "lock.pin.placeholder"), text: $pinInput)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 160)
                        .multilineTextAlignment(.center)
                    if pinError {
                        Text("lock.pin.error")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.danger)
                    }
                    PrimaryButton(title: String(localized: "lock.unlock.button"), systemImage: "checkmark") {
                        verifyPIN()
                    }
                    .padding(.horizontal, 40)
                } else {
                    PrimaryButton(title: String(localized: "lock.unlock.button"), systemImage: "faceid") {
                        authenticate()
                    }
                    .padding(.horizontal, 40)
                    .disabled(isAuthenticating)
                }

                if let services, services.appLock.isPINSet {
                    Button(showPINEntry ? String(localized: "lock.useFaceID") : String(localized: "lock.usePIN")) {
                        showPINEntry.toggle()
                        pinError = false
                    }
                    .font(Typography.caption)
                }
            }
        }
        .task {
            if !(services?.appLock.isPINSet ?? false) {
                authenticate()
            }
        }
    }

    private func authenticate() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        Task {
            _ = await services?.biometricLock.authenticate()
            isAuthenticating = false
        }
    }

    private func verifyPIN() {
        guard let services else { return }
        if services.appLock.verifyPIN(pinInput) {
            services.biometricLock.unlockWithPIN()
            pinInput = ""
            pinError = false
        } else {
            pinError = true
        }
    }
}

#Preview {
    LockGateView()
}
