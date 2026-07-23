import Foundation
import UIKit
import OneSignalFramework

/// Per OneSignal's integration guidance, this is the only file that touches the
/// OneSignal SDK directly — everything else goes through `OneSignalServicing`.
@MainActor
final class OneSignalService: NSObject, OneSignalServicing {
    private let router: DeepLinkRouterServicing
    private var didInitialize = false

    init(router: DeepLinkRouterServicing) {
        self.router = router
    }

    func initialize(appId: String) {
        guard !didInitialize, !appId.isEmpty, !appId.hasPrefix("TODO_") else { return }
        didInitialize = true
        OneSignal.Debug.setLogLevel(.LL_WARN)
        OneSignal.initialize(appId, withLaunchOptions: nil)
        OneSignal.Notifications.addClickListener(self)
    }

    func requestPushPermissionIfNeeded() async {
        guard didInitialize else { return }
        await withCheckedContinuation { continuation in
            OneSignal.Notifications.requestPermission({ _ in
                continuation.resume()
            }, fallbackToSettings: true)
        }
    }

    func syncTechnicalTags(
        appVersion: String,
        language: String,
        environment: String,
        updateNotificationsConsent: Bool,
        marketingConsent: Bool
    ) {
        guard didInitialize else { return }
        OneSignal.User.addTags([
            "app_version": appVersion,
            "language": language,
            "platform": "ios",
            "environment": environment,
            "update_notifications_consent": updateNotificationsConsent ? "true" : "false",
            "marketing_consent": marketingConsent ? "true" : "false",
        ])
    }
}

extension OneSignalService: OSNotificationClickListener {
    nonisolated func onClick(event: OSNotificationClickEvent) {
        // Extracted into plain Sendable Strings here, in the nonisolated context, rather
        // than carrying the SDK's `[AnyHashable: Any]` payload across the Task boundary.
        let additionalData = event.notification.additionalData
        let deepLinkString = additionalData?["deep_link"] as? String
        let actionURLString = additionalData?["action_url"] as? String
        Task { @MainActor in
            self.handleClick(deepLinkString: deepLinkString, actionURLString: actionURLString)
        }
    }

    private func handleClick(deepLinkString: String?, actionURLString: String?) {
        // Both keys are validated against the same allowlist (pillo:// scheme or the
        // configured CrazyBeeLabs/App Store hosts) before ever being acted on — spec
        // section 11: never open an unvalidated URL from a push payload.
        if let url = URLValidator.validated(deepLinkString), url.scheme == "pillo" {
            router.handle(url: url)
        } else if let url = URLValidator.validated(actionURLString) {
            UIApplication.shared.open(url)
        }
    }
}
