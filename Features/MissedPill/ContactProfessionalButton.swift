import SwiftUI

struct ContactProfessionalButton: View {
    var body: some View {
        SecondaryButton(title: String(localized: "missedpill.contactProfessional"), systemImage: "person.crop.circle.badge.questionmark") {
            // Phase 1: informational only — no telephony/URL wired yet, avoids guessing a
            // country-specific emergency/helpline number without validated source data.
        }
    }
}
