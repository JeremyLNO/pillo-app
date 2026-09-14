# OneSignal & APNs setup

OneSignal is used **exclusively** for CrazyBeeLabs announcements, app-update notifications, and communications the user explicitly opted into. The daily pill reminder is never routed through it — that's `LocalNotificationService`, entirely local, and works with OneSignal absent, misconfigured, or offline.

## 1. Create the OneSignal app

1. Sign in at [onesignal.com](https://onesignal.com) and create a new app named "Pillo".
2. Under **Settings ▸ Platforms**, add **Apple iOS (APNs)**.
3. **Done:** the app exists (organisation **Crazy Bee Labs**) and its App ID `04e7f4c8-7d2c-4044-83ba-1bcc517a09ed` is in `Config/Base.xcconfig`'s `ONESIGNAL_APP_ID`. Replacing it with the `TODO_` placeholder makes `OneSignalService.initialize(appId:)` a no-op again — the app stays fully functional either way.

## 2. Upload an APNs authentication key

OneSignal needs a `.p8` APNs key (not a legacy certificate) to deliver pushes:

1. **Done:** key `226GZ743S5` (« Crazy Bee Labs APNs », *Production* only / Team Scoped) is uploaded to every Crazy Bee Labs OneSignal app, and the `.p8` sits in `~/private_keys/`. Note the account already held two *Sandbox & Production* keys — Apple's cap — and a third was only accepted because it is **Production-only**; those quotas are counted separately. Apple lets you download a `.p8` once and never again.
2. Note the **Key ID** and your **Team ID** (top-right of the developer portal).
3. In OneSignal's iOS platform settings, upload the `.p8`, Key ID, and Team ID together with the app's bundle ID (`company.lno.pillo`).

## 3. Entitlements

`App/Pillo.entitlements` declares:

```xml
<key>aps-environment</key>
<string>production</string>
```

`production` **even in Debug**, and deliberately so: the real APNs environment is picked by the provisioning profile, while this value is taken literally. A `development` value in a build that ships through TestFlight yields a token the production APNs server rejects *in silence* — no error anywhere, pushes simply never arrive. Dashcam Pocket hit exactly that; every Crazy Bee Labs app now carries `production`.

## 4. SPM dependency

Already wired into `gen_pbxproj.py`'s `SPM_PACKAGES`:

```python
("OneSignal-XCFramework", "https://github.com/OneSignal/OneSignal-XCFramework", "5.5.1", ["OneSignalFramework"])
```

`xcodebuild -resolvePackageDependencies` (or a normal build) fetches it automatically — no manual Xcode GUI package-add step needed. Bump the version string here (and re-run `gen_pbxproj.py`) to update.

## 5. What the app actually does with it

`Core/Services/OneSignal/OneSignalService.swift` is the **only** file that imports `OneSignalFramework`, per OneSignal's own integration guidance:

- `initialize(appId:)` — called once in `PilloApp.init()`, unconditionally (no-ops on the placeholder ID).
- `requestPushPermissionIfNeeded()` — called only when the user turns on "Notifications de mise à jour" or "Communications facultatives" in Réglages ▸ Notifications CrazyBeeLabs (`NotificationsCrazyBeeLabsSection`). Never prompted automatically at launch.
- `syncTechnicalTags(...)` — sends **only** technical tags: `app_version`, `language`, `platform`, `environment`, `update_notifications_consent`, `marketing_consent`. Grep the file if you're auditing — no pill, dose, symptom, or contraception field is ever referenced here.
- Notification clicks are handled by `OSNotificationClickListener.onClick`, which reads `deep_link` / `action_url` from the payload's `additionalData` and validates both through `URLValidator` (see README) before acting — an untrusted push can only route to an allow-listed internal route or `crazybeelabs.com`/App Store URL, never an arbitrary external site.

## 6. Sending an update-availability push

Two independent mechanisms exist (spec section 11) — use either or both:

**A. OneSignal push**, targeted at users tagged with an old `app_version`. Suggested payload `additionalData`:

```json
{
  "type": "app_update",
  "deep_link": "pillo://update",
  "action_url": "https://apps.apple.com/app/id<APP_STORE_ID>"
}
```

Tapping it routes to the Réglages tab (where the update banner lives) or opens the App Store, per `URLValidator`'s allow-list.

**B. Remote-config JSON**, checked on every foreground via `UpdateAvailabilityService` (no OneSignal dependency at all — works even for users who declined push). Host this at the URL you put in `REMOTE_CONFIG_URL`:

```json
{
  "latestVersion": "1.4.0",
  "minimumSupportedVersion": "1.1.0",
  "appStoreURL": "https://apps.apple.com/app/id<APP_STORE_ID>",
  "message": {
    "fr": "Une nouvelle version est disponible.",
    "en": "A new version is available.",
    "es": "Hay una nueva versión disponible.",
    "de": "Eine neue Version ist verfügbar.",
    "pt": "Uma nova versão está disponível."
  }
}
```

- If the running version is below `minimumSupportedVersion`, the app shows a **blocking** full-screen update prompt (`MandatoryUpdateView`) with no dismiss.
- If only below `latestVersion`, it's a dismissible row in Réglages — never a full-screen interruption.
- `appStoreURL` is validated by `URLValidator` — a non-`apps.apple.com`/`itunes.apple.com` host is silently rejected (treated as "no update"), so a compromised or misconfigured host can't redirect users off-App-Store.
- Comparison logic lives in `Core/Services/SemanticVersion.swift`, fully unit-tested in `Tests/SemanticVersionTests.swift`.

Never scrape App Store pages for version info — this JSON file is the only source of truth.

## 7. Testing a push

1. In OneSignal's dashboard, use **Messages ▸ New Push** targeting a test device (install the app on a real device or a Simulator that supports push — Simulator push requires macOS 12+/Xcode 14+ and works fine for testing `additionalData` handling, though real APNs delivery to Simulator needs `xcrun simctl push`, not OneSignal's dashboard sender, which targets real devices).
2. For a Simulator-only smoke test of the click-handling code path without a real push, use `xcrun simctl push <device> company.lno.pillo payload.apns` with a synthetic payload matching OneSignal's `aps` + `custom.a` (`additionalData`) shape.
