import SwiftUI

struct PillCountStepperView: View {
    @Binding var count: Int

    var body: some View {
        HStack {
            Label(String(localized: "missedpill.pillCount.question"), systemImage: "pills")
                .font(Typography.headline)
            Spacer()
            HStack(spacing: 16) {
                Button { count = max(1, count - 1) } label: {
                    Image(systemName: "minus.circle.fill")
                }
                Text("\(count)")
                    .font(Typography.headline)
                    .frame(minWidth: 24)
                Button { count = min(10, count + 1) } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            .foregroundStyle(Palette.primary)
            .font(.title2)
        }
    }
}
