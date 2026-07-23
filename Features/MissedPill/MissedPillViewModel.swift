import Foundation
import Observation

enum DelayBucket: String, CaseIterable, Identifiable {
    case lessThan12h
    case between12and24h
    case moreThan24h

    var id: String { rawValue }

    var approximateMinutes: Int {
        switch self {
        case .lessThan12h: return 60
        case .between12and24h: return 18 * 60
        case .moreThan24h: return 30 * 60
        }
    }
}

@Observable
@MainActor
final class MissedPillViewModel {
    var delayBucket: DelayBucket = .lessThan12h
    var pillsMissed: Int = 1
    var weekInPack: Int = 1
    var recentIntercourse: Bool = false

    func guidance(pillType: PillType, services: ServiceContainer) -> MissedPillGuidance {
        let context = MissedPillContext(
            pillType: pillType,
            country: Locale.current.region?.identifier ?? "FR",
            delayMinutes: delayBucket.approximateMinutes,
            pillsMissed: pillsMissed,
            weekInPack: weekInPack,
            recentIntercourse: recentIntercourse
        )
        return services.ruleEngine.guidance(for: context)
    }
}
