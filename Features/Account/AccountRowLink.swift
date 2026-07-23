import SwiftUI

/// Opens the CrazyBeeLabs account-creation page in the system browser. No in-app auth —
/// the account is entirely optional and never required to use reminders (spec section 19).
struct AccountRowLink: View {
    let url: URL

    var body: some View {
        Link(String(localized: "settings.crazybeelabs.createAccount"), destination: url)
    }
}
