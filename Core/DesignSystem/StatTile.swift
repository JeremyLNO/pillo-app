import SwiftUI

struct StatTile: View {
    let systemImage: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String

    var body: some View {
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Circle().fill(iconColor.opacity(0.15))
                    Image(systemName: systemImage)
                        .foregroundStyle(iconColor)
                }
                .frame(width: 36, height: 36)

                Text(title)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)

                (Text(value).font(Typography.statValue) + Text(" " + unit).font(Typography.caption))
                    .foregroundStyle(Palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(unit)")
    }
}

#Preview {
    HStack {
        StatTile(systemImage: "flame.fill", iconColor: Palette.warning, title: "Série", value: "18", unit: "jours")
        StatTile(systemImage: "checkmark.shield.fill", iconColor: Palette.success, title: "Observance", value: "97", unit: "%")
        StatTile(systemImage: "pills.fill", iconColor: Palette.primary, title: "Stock", value: "2", unit: "plaquettes")
    }
    .padding()
    .background(Palette.background)
}
