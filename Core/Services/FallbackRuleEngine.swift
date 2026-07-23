import Foundation

/// Phase 1 ships zero real `MedicalRule` entries — populating them requires medically
/// reviewed, versioned, sourced content per section 12 of the spec, which is explicitly
/// out of scope until a health professional has validated it. This engine always returns
/// the spec's mandated generic fallback so the app never presents an unreviewed
/// recommendation as medical guidance.
@MainActor
final class FallbackRuleEngine: RuleEngineServicing {
    func guidance(for context: MissedPillContext) -> MissedPillGuidance {
        .fallback(message: String(localized: "missedpill.fallback.message"))
    }
}
