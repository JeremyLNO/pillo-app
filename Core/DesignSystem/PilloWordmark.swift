import SwiftUI

struct PilloWordmark: View {
    var size: CGFloat = 32

    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            Text("Pillo")
                .font(.system(size: size, weight: .heavy, design: .serif))
                .foregroundStyle(Palette.primaryDeep)
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.28))
                .foregroundStyle(Palette.accentPink)
                .offset(y: size * 0.05)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pillo")
    }
}

#Preview {
    PilloWordmark()
        .padding()
        .background(Palette.background)
}
