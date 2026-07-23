import SwiftUI

/// Blocking screen shown only when the running version is below
/// `minimumSupportedVersion` (spec section 11's "mise à jour minimale requise"). No
/// dismiss action — the optional-update case never reaches this view.
struct MandatoryUpdateView: View {
    let update: UpdateCheckResult

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Palette.primary)
                Text("update.mandatory.title")
                    .font(Typography.title)
                    .multilineTextAlignment(.center)
                Text(update.message.isEmpty ? String(localized: "update.mandatory.defaultMessage") : update.message)
                    .font(Typography.body)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                PrimaryButton(title: String(localized: "update.mandatory.button"), systemImage: "arrow.down.circle") {
                    UIApplication.shared.open(update.appStoreURL)
                }
                .padding(.horizontal, 40)
            }
            .padding(28)
        }
    }
}
