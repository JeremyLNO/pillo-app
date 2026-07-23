import SwiftUI
import SwiftData

struct StockView: View {
    @Environment(\.services) private var services
    @Query private var stockEntries: [StockEntry]

    var body: some View {
        Group {
            if let stock = stockEntries.first, let services {
                Form {
                    Section(String(localized: "stock.section.pack")) {
                        Stepper(value: Binding(
                            get: { stock.remainingPacks },
                            set: { newValue in
                                stock.remainingPacks = newValue
                                stock.lastUpdatedAt = .now
                                Task { await services.stock.syncLowStockReminder(for: stock) }
                            }
                        ), in: 0...20) {
                            Text(String(format: String(localized: "settings.stock.remainingPacks"), stock.remainingPacks))
                        }
                        Stepper(value: Binding(get: { stock.pillsPerPack }, set: { stock.pillsPerPack = $0 }), in: 1...31) {
                            Text(String(format: String(localized: "stock.pillsPerPack"), stock.pillsPerPack))
                        }
                        HStack {
                            Text("stock.estimatedDepletion")
                            Spacer()
                            Text(services.stock.estimatedDepletionDate(for: stock), format: .dateTime.day().month().year())
                                .foregroundStyle(Palette.textSecondary)
                        }
                    }

                    Section(String(localized: "stock.section.alerts")) {
                        Stepper(value: Binding(
                            get: { stock.lowStockThreshold },
                            set: { newValue in
                                stock.lowStockThreshold = newValue
                                Task { await services.stock.syncLowStockReminder(for: stock) }
                            }
                        ), in: 0...5) {
                            Text(String(format: String(localized: "stock.lowStockThreshold"), stock.lowStockThreshold))
                        }
                        Toggle(String(localized: "settings.stock.renewalReminder"), isOn: Binding(
                            get: { stock.renewalReminderEnabled },
                            set: { newValue in
                                stock.renewalReminderEnabled = newValue
                                Task { await services.stock.syncLowStockReminder(for: stock) }
                            }
                        ))
                        if services.stock.isLowStock(stock) {
                            Label(String(localized: "stock.lowStockWarning"), systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(Palette.warning)
                        }
                    }

                    Section(String(localized: "stock.section.prescription")) {
                        DatePicker(
                            String(localized: "stock.prescriptionExpiration"),
                            selection: Binding(
                                get: { stock.prescriptionExpirationDate ?? .now },
                                set: { stock.prescriptionExpirationDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                        DatePicker(
                            String(localized: "settings.stock.nextAppointment"),
                            selection: Binding(
                                get: { stock.nextMedicalAppointment ?? .now },
                                set: { stock.nextMedicalAppointment = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                }
                .navigationTitle(Text("settings.stock.title"))
            } else {
                ProgressView()
            }
        }
    }
}

#Preview {
    NavigationStack {
        StockView()
            .modelContainer(PersistenceController.preview())
    }
}
