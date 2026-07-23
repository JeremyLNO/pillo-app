import SwiftUI

struct BlisterLegendView: View {
    var body: some View {
        HStack(spacing: 18) {
            item(state: .taken, label: "blister.legend.taken")
            item(state: .today, label: "blister.legend.today")
            item(state: .upcoming, label: "blister.legend.upcoming")
            item(state: .placeboUpcoming, label: "blister.legend.placebo")
        }
        .font(Typography.caption)
        .foregroundStyle(Palette.textSecondary)
    }

    private func item(state: BlisterCellState, label: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            BlisterCellView(dayNumber: 0, state: state, showsNumber: false)
                .frame(width: 16, height: 16)
            Text(label)
        }
    }
}

#Preview {
    BlisterLegendView().padding()
}
