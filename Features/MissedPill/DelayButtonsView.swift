import SwiftUI

struct DelayButtonsView: View {
    @Binding var selection: DelayBucket

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "missedpill.delay.question"), systemImage: "clock")
                .font(Typography.headline)
            HStack(spacing: 8) {
                ForEach(DelayBucket.allCases) { bucket in
                    Button {
                        selection = bucket
                    } label: {
                        Text(label(for: bucket))
                            .font(Typography.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selection == bucket ? Palette.primary : Palette.primary.opacity(0.08))
                            .foregroundStyle(selection == bucket ? .white : Palette.primaryDeep)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func label(for bucket: DelayBucket) -> LocalizedStringKey {
        switch bucket {
        case .lessThan12h: return "missedpill.delay.lessThan12h"
        case .between12and24h: return "missedpill.delay.between12and24h"
        case .moreThan24h: return "missedpill.delay.moreThan24h"
        }
    }
}
