import XCTest
import SwiftData
@testable import Pillo

@MainActor
final class StockServiceTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var service: StockService!

    override func setUp() {
        super.setUp()
        let schema = Schema([StockEntry.self])
        container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        context = container.mainContext
        service = StockService(context: context)
    }

    func testCurrentStockCreatesDefaultEntryIfNoneExists() throws {
        let stock = try service.currentStock()
        XCTAssertEqual(stock.remainingPacks, 1)
        XCTAssertEqual(stock.pillsPerPack, 28)
    }

    func testIsLowStockUsesThreshold() {
        let entry = StockEntry(remainingPacks: 1, lowStockThreshold: 1)
        XCTAssertTrue(service.isLowStock(entry))
        let plenty = StockEntry(remainingPacks: 5, lowStockThreshold: 1)
        XCTAssertFalse(service.isLowStock(plenty))
    }

    func testDecrementPackNeverGoesNegative() throws {
        context.insert(StockEntry(remainingPacks: 0))
        try context.save()
        try service.decrementPack()
        let stock = try service.currentStock()
        XCTAssertEqual(stock.remainingPacks, 0)
    }

    func testEstimatedDepletionDateMatchesTotalPillCount() {
        let entry = StockEntry(remainingPacks: 2, pillsPerPack: 28)
        let depletion = service.estimatedDepletionDate(for: entry)
        let days = Calendar.current.dateComponents([.day], from: .now, to: depletion).day ?? 0
        XCTAssertTrue(abs(days - 56) <= 1)
    }
}
