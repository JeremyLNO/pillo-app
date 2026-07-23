import SwiftUI

struct FallbackGuidanceCard: View {
    let message: String

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(String(localized: "missedpill.guidance.title"), systemImage: "sun.max.fill")
                        .font(Typography.headline)
                        .foregroundStyle(Palette.warning)
                    Spacer()
                    Text("missedpill.guidance.indicative")
                        .font(Typography.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Palette.warning.opacity(0.15))
                        .foregroundStyle(Palette.warning)
                        .clipShape(Capsule())
                }
                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(Palette.textPrimary)
                Text("missedpill.guidance.disclaimer")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
    }
}
