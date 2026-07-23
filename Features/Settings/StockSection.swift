import SwiftUI

struct StockSection: View {
    @Bindable var stock: StockEntry

    var body: some View {
        Section(String(localized: "settings.stock.title")) {
            NavigationLink {
                StockView()
            } label: {
                HStack {
                    Text("settings.stock.remainingPacks.short")
                    Spacer()
                    Text("\(stock.remainingPacks)").foregroundStyle(Palette.textSecondary)
                }
            }
            Toggle(String(localized: "settings.stock.renewalReminder"), isOn: $stock.renewalReminderEnabled)
        }
    }
}
