# Adding a medical rule to the missed-pill assistant

**No real medical rule ships in this codebase.** `FallbackRuleEngine` always returns the spec's mandated generic message:

> "Consultez la notice de votre pilule ou contactez rapidement un pharmacien, une sage-femme ou un médecin."

This is intentional, not an oversight. Per the governing spec: *"N'invente aucune règle médicale. N'utilise aucun texte médical non validé comme recommandation de production. Ne jamais utiliser un LLM génératif pour produire directement une recommandation médicale."* Do not ask an AI coding assistant (this one included) to draft rule content — the recommendations, thresholds, and warnings must come from a licensed medical reviewer working from an authoritative source (a national health authority's contraception guidelines, a pill manufacturer's approved package insert, etc.).

## What the engine architecture already supports

`Core/Services/RuleEngineServicing.swift` defines the exact shape the spec requires:

```swift
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
}
```

`MissedPillContext` (pill type, country, delay, pills missed, week in pack, recent intercourse) is what `MissedPillViewModel` builds from the assistant's form and passes to `RuleEngineServicing.guidance(for:)`.

## Steps to add a real rule (once medically reviewed)

1. **Get it reviewed first.** Every field above except `ruleID` must trace back to a named medical reviewer and a dated, citable source. Do not write placeholder values "to fill the struct" — an unreviewed rule is worse than the generic fallback, because it *looks* authoritative.
2. Write a new `RuleEngineServicing` implementation (e.g. `ValidatedRuleEngine`) that holds an array of `MedicalRule` and matches `MissedPillContext` against `inputConditions` (design the matching logic to fit however the reviewed source actually branches — don't force it into a shape that doesn't match the real guidance).
3. Respect `validFrom`/`validUntil` — a rule outside its validity window must not match; fall through to `.fallback(message:)` instead.
4. Wire a way to **disable a single rule remotely** without an App Store release (spec: "une possibilité de désactiver à distance une règle erronée") — e.g. a `disabledRuleIDs: Set<String>` fetched alongside `REMOTE_CONFIG_URL` (see `docs/ONESIGNAL_SETUP.md`), checked before a rule is allowed to match.
5. Every recommendation string needs its own String Catalog key per supported language (fr/en/es/de/pt) — translated by someone competent in medical terminology in that language, not machine-translated from French. Do not reuse `missedpill.fallback.message`'s casual translation approach for real medical content.
6. `emergencyWarnings` must always be shown *more* prominently than `recommendedActions` in `MissedPillView` — if the UI treats them identically, that's a bug to fix before shipping the rule, not a rule-content problem.
7. Update `ServiceContainer.swift`'s `self.ruleEngine = FallbackRuleEngine()` line to use the new implementation once real rules exist for at least one `pillType`/`country` pair — keep `FallbackRuleEngine` as the engine for any combination without a reviewed rule (never let a partially-populated engine silently fall through to nothing).
8. Add unit tests asserting: correct rule selected for a given context, fallback used when no rule matches, fallback used when the only matching rule is outside `validFrom`/`validUntil`, fallback used when the rule ID is in `disabledRuleIDs`.

## What "not a diagnosis" means in the UI

`MissedPillView`/`FallbackGuidanceCard` already render the "Conseil indicatif" badge and the "Ce résultat n'est pas un diagnostic médical" disclaimer around any guidance shown — real rule content must keep both, not replace them with more confident-sounding language.
