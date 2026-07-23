import SwiftUI
import ContactsUI

/// Opt-in, local-only safety net (spec-adjacent feature, added on top of the original
/// spec): if a dose stays unconfirmed past `trustedContactAlertDelayHours`, Pillo offers
/// to pre-fill an SMS to this contact — the user always has to review and tap Send
/// themselves in Messages. Nothing is ever sent automatically or silently, which matters
/// a lot for an app tracking contraception (see `NotificationDelegate.openTrustedContactMessage`).
struct TrustedContactSection: View {
    @Bindable var preferences: NotificationPreferences
    @State private var showingContactPicker = false

    private static let delayOptions = [1, 2, 3, 6, 12]

    var body: some View {
        Section {
            Toggle(String(localized: "settings.trustedContact.enabled"), isOn: $preferences.trustedContactEnabled)

            if preferences.trustedContactEnabled {
                Button {
                    showingContactPicker = true
                } label: {
                    HStack {
                        Text("settings.trustedContact.contact")
                            .foregroundStyle(Palette.textPrimary)
                        Spacer()
                        Text(preferences.trustedContactName ?? String(localized: "settings.trustedContact.choose"))
                            .foregroundStyle(Palette.textSecondary)
                    }
                }

                Picker(String(localized: "settings.trustedContact.delay"), selection: $preferences.trustedContactAlertDelayHours) {
                    ForEach(Self.delayOptions, id: \.self) { hours in
                        Text(String(format: String(localized: "settings.trustedContact.delay.hours"), hours)).tag(hours)
                    }
                }
            }
        } header: {
            Text("settings.trustedContact.title")
        } footer: {
            Text("settings.trustedContact.footer")
        }
        .sheet(isPresented: $showingContactPicker) {
            TrustedContactPickerView { picked in
                preferences.trustedContactName = picked.name
                preferences.trustedContactPhoneNumber = picked.phoneNumber
            }
        }
    }
}

private struct TrustedContactPickerView: UIViewControllerRepresentable {
    struct PickedContact {
        let name: String
        let phoneNumber: String
    }

    let onPick: (PickedContact) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        private let onPick: (PickedContact) -> Void

        init(onPick: @escaping (PickedContact) -> Void) {
            self.onPick = onPick
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            guard let phoneNumber = contact.phoneNumbers.first?.value.stringValue else { return }
            let name = CNContactFormatter.string(from: contact, style: .fullName) ?? phoneNumber
            onPick(PickedContact(name: name, phoneNumber: phoneNumber))
        }
    }
}
