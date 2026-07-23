import Foundation

/// Mirrors the spec's section 12 rule shape exactly, so real, medically-reviewed rule
/// content can be dropped in later without touching the engine's call sites. No rule
/// with this shape is populated in Phase 1 — see `FallbackRuleEngine`.
struct MedicalRule: Sendable, Identifiable {
    let ruleID: String
    let pillType: PillType
    let country: String
    let validFrom: Date
    let validUntil: Date?
    let medicalSource: String
    let reviewedBy: String
    let medicalReviewDate: Date
    let inputConditions: String
    let recommendedActions: [String]
    let emergencyWarnings: [String]

    var id: String { ruleID }
}

struct MissedPillContext: Sendable {
    let pillType: PillType
    let country: String
    /// Minutes late, if known.
    let delayMinutes: Int?
    let pillsMissed: Int
    let weekInPack: Int
    let recentIntercourse: Bool
}

enum MissedPillGuidance: Sendable {
    case rule(MedicalRule)
    /// No validated rule matches — always the safe default until real medical content
    /// (reviewed and versioned per section 12) is loaded.
    case fallback(message: String)
}

@MainActor
protocol RuleEngineServicing {
    func guidance(for context: MissedPillContext) -> MissedPillGuidance
}
