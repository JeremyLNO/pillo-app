import SwiftUI

/// Phase 1 static placeholders (spec section 15's real symptom tracking screen is a later
/// phase) — shown here only so the Suivi layout matches the approved mockup.
struct SymptomChipsView: View {
    private let placeholderKeys: [LocalizedStringKey] = [
        "symptom.spotting", "symptom.mood", "symptom.headache", "symptom.bloating",
    ]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("history.symptoms.title")
                    .font(Typography.headline)
                FlowChips(keys: placeholderKeys)
            }
        }
    }
}

private struct FlowChips: View {
    let keys: [LocalizedStringKey]

    var body: some View {
        HStack {
            ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                Text(key)
                    .font(Typography.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Palette.primary.opacity(0.10))
                    .foregroundStyle(Palette.primaryDeep)
                    .clipShape(Capsule())
            }
            Spacer(minLength: 0)
        }
    }
}
