import SwiftUI

struct BlisterGridView: View {
    let packPosition: PackPosition
    let cellStates: [BlisterCellState]
    let onSelectDay: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(cellStates.enumerated()), id: \.offset) { index, state in
                Button {
                    onSelectDay(index + 1)
                } label: {
                    BlisterCellView(dayNumber: index + 1, state: state)
                        .frame(height: 32)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
