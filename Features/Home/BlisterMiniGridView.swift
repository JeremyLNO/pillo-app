import SwiftUI

struct BlisterMiniGridView: View {
    let packPosition: PackPosition
    let cellStates: [BlisterCellState]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("home.blisterMini.title")
                        .font(Typography.headline)
                    Spacer()
                    Text(String(format: String(localized: "home.blisterMini.dayProgress"), packPosition.dayInPack, packPosition.packSize))
                        .font(Typography.caption)
                        .foregroundStyle(Palette.textSecondary)
                }
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(cellStates.enumerated()), id: \.offset) { index, state in
                        BlisterCellView(dayNumber: index + 1, state: state, showsNumber: false)
                            .frame(height: 20)
                    }
                }
            }
        }
    }
}
