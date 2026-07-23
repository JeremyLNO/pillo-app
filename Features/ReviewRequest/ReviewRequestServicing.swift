import Foundation

/// Decision logic only — the actual `AppStore.requestReview(in:)` call must happen from
/// a SwiftUI view via `@Environment(\.requestReview)` (StoreKit's documented API shape),
/// so this service just answers "should I ask right now?" and records that an attempt
/// was made. Spec section 18: first launch after >=24h, never a custom Yes/No popup,
/// never gated on "only happy users," attempted at most once.
@MainActor
protocol ReviewRequestServicing {
    func shouldRequestReview(preferences: UserPreferences) -> Bool
    func markRequested(preferences: UserPreferences)
}

final class ReviewRequestService: ReviewRequestServicing {
    private let minimumInterval: TimeInterval

    init(minimumInterval: TimeInterval = 24 * 60 * 60) {
        self.minimumInterval = minimumInterval
    }

    func shouldRequestReview(preferences: UserPreferences) -> Bool {
        guard !preferences.reviewRequestAttempted else { return false }
        return Date.now.timeIntervalSince(preferences.installDate) >= minimumInterval
    }

    func markRequested(preferences: UserPreferences) {
        preferences.reviewRequestAttempted = true
        preferences.reviewRequestDate = .now
    }
}
