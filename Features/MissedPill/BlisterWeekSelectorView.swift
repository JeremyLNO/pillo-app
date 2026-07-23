import SwiftUI

struct BlisterWeekSelectorView: View {
    @Binding var selectedWeek: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(String(localized: "missedpill.week.question"), systemImage: "calendar")
                .font(Typography.headline)
            HStack(spacing: 8) {
                ForEach(1...4, id: \.self) { week in
                    Button {
                        selectedWeek = week
                    } label: {
                        Text(String(format: String(localized: "missedpill.week.label"), week))
                            .font(Typography.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(selectedWeek == week ? Palette.primary : Palette.primary.opacity(0.08))
                            .foregroundStyle(selectedWeek == week ? .white : Palette.primaryDeep)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}
