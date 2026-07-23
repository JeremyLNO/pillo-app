import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let label: String
    let value: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.primary.opacity(0.15), lineWidth: 8)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(Palette.success, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
            VStack(spacing: 2) {
                Text(label)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.textSecondary)
                Text(value)
                    .font(Typography.headline)
                    .foregroundStyle(Palette.textPrimary)
            }
        }
        .frame(width: 92, height: 92)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ProgressRing(progress: 12.0 / 28.0, label: "Jour", value: "12/28")
        .padding()
        .background(Palette.background)
}
