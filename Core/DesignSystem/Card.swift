import SwiftUI

struct Card<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Palette.cardCornerRadius, style: .continuous)
                    .fill(Palette.cardBackground)
                    .shadow(color: Palette.cardShadow.opacity(0.12), radius: 16, x: 0, y: 8)
            )
    }
}

#Preview {
    Card {
        Text("Card content")
    }
    .padding()
    .background(Palette.background)
}
