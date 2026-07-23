import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isProminent: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .background(
            LinearGradient(colors: [Palette.primary, Palette.primaryDeep], startPoint: .leading, endPoint: .trailing)
        )
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: Palette.buttonCornerRadius, style: .continuous))
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .foregroundStyle(Palette.primaryDeep)
        .overlay(
            RoundedRectangle(cornerRadius: Palette.buttonCornerRadius, style: .continuous)
                .stroke(Palette.primary.opacity(0.35), lineWidth: 1.5)
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        PrimaryButton(title: "J'ai pris ma pilule", systemImage: "checkmark.circle.fill") {}
        SecondaryButton(title: "Reporter", systemImage: "clock") {}
    }
    .padding()
    .background(Palette.background)
}
