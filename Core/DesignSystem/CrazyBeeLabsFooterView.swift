import SwiftUI

/// Shared, reusable footer for the bottom of Réglages (spec section 21). Sibling
/// CrazyBeeLabs apps usually inline this per-screen; the spec explicitly asks for a
/// proper reusable, accessible component here, so this is a real shared view rather
/// than a copy-pasted block.
struct CrazyBeeLabsFooterView: View {
    let websiteURL: URL

    var body: some View {
        Link(destination: websiteURL) {
            VStack(spacing: 10) {
                Image("CrazyBeeLabsLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)

                Text("settings.crazybeelabs.footer.tagline")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)

                Text(websiteURL.host ?? "crazybeelabs.com")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.primary)
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("settings.crazybeelabs.footer.accessibilityLabel"))
    }
}

#Preview {
    CrazyBeeLabsFooterView(websiteURL: URL(string: "https://crazybeelabs.com/")!)
        .background(Palette.background)
}
