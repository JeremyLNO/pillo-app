import SwiftUI
import SwiftData
import Combine

struct RootView: View {
    @Environment(\.services) private var services
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview

    @Query private var preferencesList: [UserPreferences]
    @Query(filter: #Predicate<PillProfile> { $0.isActive }) private var activeProfiles: [PillProfile]
    @Query private var notificationPreferencesList: [NotificationPreferences]

    @State private var showTimeZoneSheet = false
    @State private var mandatoryUpdate: UpdateCheckResult?
    @State private var queuedDeepLinkURL: URL?

    private var preferences: UserPreferences? { preferencesList.first }

    var body: some View {
        Group {
            if let preferences, !preferences.hasSeenCommitmentScreen {
                CommitmentView(configuration: services?.configuration ?? .current) {
                    preferences.hasSeenCommitmentScreen = true
                    try? modelContext.save()
                }
            } else if let preferences, !preferences.completedOnboarding {
                OnboardingView()
            } else {
                ZStack {
                    MainTabView()
                        .environment(\.discreetModeEnabled, preferences?.discreetModeEnabled ?? false)

                    if let services, services.biometricLock.isLocked {
                        LockGateView()
                            .transition(.opacity)
                    }
                }
            }
        }
        .sheet(isPresented: $showTimeZoneSheet) {
            TimeZoneChangeSheet { strategy in
                applyTimeZoneStrategy(strategy)
                showTimeZoneSheet = false
            }
        }
        .fullScreenCover(item: $mandatoryUpdate) { update in
            MandatoryUpdateView(update: update)
        }
        .task { await refreshNotificationsIfNeeded() }
        .task { await checkForUpdateIfNeeded() }
        .task { maybeRequestReview() }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onChange(of: services?.biometricLock.isLocked) { _, isLocked in
            // Never let a deep link bypass the lock (spec section 22): if one arrived
            // while locked, it was queued below and only applied once unlocked.
            guard isLocked == false, let queuedDeepLinkURL else { return }
            services?.deepLinkRouter.handle(url: queuedDeepLinkURL)
            self.queuedDeepLinkURL = nil
        }
        .onOpenURL { url in
            guard let preferences, preferences.completedOnboarding else { return }
            if services?.biometricLock.isLocked == true {
                queuedDeepLinkURL = url
            } else {
                services?.deepLinkRouter.handle(url: url)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: DoseChangeNotifying.name)) { _ in
            refreshWidgetSnapshot()
        }
    }

    /// Recomputes the iOS-widget/Watch-complication snapshot. Called after every dose
    /// mutation (via the `DoseChangeNotifying` notification) and alongside the regular
    /// notification refresh cycle, so the widgets never lag behind by more than the time
    /// to the next foreground/mutation.
    private func refreshWidgetSnapshot() {
        guard let services else { return }
        let profile = activeProfiles.first
        let events = profile.flatMap { try? services.pillSchedule.doseEvents(for: $0) } ?? []
        WidgetBridge.refresh(
            profile: profile,
            events: events,
            userPreferences: preferences,
            pillSchedule: services.pillSchedule,
            watchConnectivity: services.watchConnectivity
        )
    }

    private func maybeRequestReview() {
        guard let services, let preferences, preferences.completedOnboarding else { return }
        guard services.reviewRequest.shouldRequestReview(preferences: preferences) else { return }
        requestReview()
        services.reviewRequest.markRequested(preferences: preferences)
        try? modelContext.save()
    }

    private func checkForUpdateIfNeeded() async {
        guard let services else { return }
        guard let result = await services.updateAvailability.checkForUpdate() else { return }
        if result.isMandatory {
            mandatoryUpdate = result
        }
        // Optional updates are surfaced as a dismissible row in Réglages (CrazyBeeLabsSection
        // reads the same service), never as an interruption.
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        guard let services, let preferences else { return }
        switch newPhase {
        case .background:
            services.biometricLock.noteDidEnterBackground()
            BackgroundRefreshTask.scheduleNext()
        case .active:
            services.biometricLock.noteWillEnterForeground(biometricLockEnabled: preferences.biometricLockEnabled)
            checkTimeZoneChange()
            Task { await refreshNotificationsIfNeeded() }
        default:
            break
        }
    }

    private func checkTimeZoneChange() {
        guard let preferences else { return }
        let currentIdentifier = TimeZone.current.identifier
        defer { preferences.lastKnownTimeZoneIdentifier = currentIdentifier }

        guard let lastKnown = preferences.lastKnownTimeZoneIdentifier, lastKnown != currentIdentifier else { return }
        let strategy = notificationPreferencesList.first?.timeZoneChangeStrategy ?? .askEachTime
        switch strategy {
        case .askEachTime:
            showTimeZoneSheet = true
        case .alwaysKeepLocalTime:
            break // scheduledDateTime is always computed in the device's current calendar/timezone already
        case .alwaysKeepElapsedInterval:
            applyElapsedIntervalShift(fromIdentifier: lastKnown, toIdentifier: currentIdentifier)
        }
    }

    private func applyTimeZoneStrategy(_ strategy: TimeZoneChangeStrategy) {
        guard let notificationPreferences = notificationPreferencesList.first else { return }
        notificationPreferences.timeZoneChangeStrategy = strategy
        if strategy == .alwaysKeepElapsedInterval, let lastKnown = preferences?.lastKnownTimeZoneIdentifier {
            applyElapsedIntervalShift(fromIdentifier: lastKnown, toIdentifier: TimeZone.current.identifier)
        }
        try? modelContext.save()
    }

    /// Shifts each active profile's intake time (and every not-yet-taken future dose) by the
    /// raw offset delta between the old and new timezones, so the true elapsed interval
    /// between doses is preserved rather than silently snapping to the new local clock time.
    private func applyElapsedIntervalShift(fromIdentifier: String, toIdentifier: String) {
        guard let services else { return }
        guard let oldZone = TimeZone(identifier: fromIdentifier), let newZone = TimeZone(identifier: toIdentifier) else { return }
        let deltaSeconds = newZone.secondsFromGMT() - oldZone.secondsFromGMT()
        guard deltaSeconds != 0 else { return }

        for profile in activeProfiles {
            profile.usualIntakeTime = profile.usualIntakeTime.addingTimeInterval(TimeInterval(-deltaSeconds))
            if let events = try? services.pillSchedule.doseEvents(for: profile) {
                for event in events where event.status == .scheduled || event.status == .placebo {
                    event.scheduledTime = event.scheduledTime.addingTimeInterval(TimeInterval(-deltaSeconds))
                }
            }
        }
        try? modelContext.save()
    }

    private func refreshNotificationsIfNeeded() async {
        guard let services, let notificationPreferences = notificationPreferencesList.first else { return }
        for profile in activeProfiles {
            guard let events = try? services.pillSchedule.doseEvents(for: profile) else { continue }
            await services.localNotification.refreshSchedule(for: profile, events: events, preferences: notificationPreferences)
        }
        refreshWidgetSnapshot()
    }
}
