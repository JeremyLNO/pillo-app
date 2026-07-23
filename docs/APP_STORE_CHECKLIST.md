# App Store submission checklist

## Before archiving

- [ ] `Config/Base.xcconfig`: `APP_STORE_ID` set to the real App Store Connect numeric ID (currently `0000000000`).
- [ ] `Config/Base.xcconfig`: `ONESIGNAL_APP_ID` set to the real OneSignal App ID (currently `TODO_ONESIGNAL_APP_ID`) — or leave as-is if shipping without OneSignal for v1 (the app works fine either way).
- [ ] `Config/Base.xcconfig`: `PRIVACY_POLICY_URL` and `TERMS_URL` point at real, published pages (see `docs/DATA_POLICY.md` for the content to publish).
- [ ] `Resources/Assets.xcassets/AppIcon.appiconset`: replace the placeholder gradient+pill icon with a real design (all required sizes — the single 1024×1024 "universal" entry is sufficient for Xcode 14+/iOS 17+ single-size icons).
- [ ] `App/Pillo.entitlements`: confirm `aps-environment` reads `production` after archiving with a distribution provisioning profile (Xcode usually rewrites this automatically — verify, don't assume).
- [ ] `DEVELOPMENT_TEAM` in `Config/Base.xcconfig` (`2E6D4Q69QB`) is this dev account's team — replace with the shipping team's ID if different.
- [ ] Run the full test suite (`README.md`'s "Running the tests" section) and confirm 0 failures.
- [ ] Manually walk onboarding end-to-end on a real device (not just Simulator) — Face ID, notification permission, and Keychain (PIN) all behave differently on-device than in Simulator.

## Privacy & permissions

- [ ] `NSFaceIDUsageDescription` in `App/Info.plist` reads clearly and matches what Face ID is actually used for (app unlock only).
- [ ] App Store Connect's **App Privacy** questionnaire matches `docs/DATA_POLICY.md` exactly — in particular: Health & Fitness data is collected but **not linked to identity and not used for tracking** (no account, no cross-app tracking, no ad network). Declare `DoseEvent`/`SymptomEntry` categories accurately; declare OneSignal's technical tags (device ID, app version) as "used for App Functionality," not "used for tracking."
- [ ] No `NSUserTrackingUsageDescription` needed — the app doesn't use IDFA or ATT.
- [ ] Confirm no analytics SDK crept in beyond `NoOpAnalyticsService` (`grep -r "import.*Analytics"` across `Core/` and `Features/`).

## Content & functionality review risk areas

- [ ] The missed-pill assistant (`MissedPillView`) only ever shows the generic, non-diagnostic fallback message — confirm no real medical rule content was added without following `docs/MEDICAL_RULE_GUIDE.md`'s review process (Apple review, and more importantly patient safety, both require this).
- [ ] Every "Conseil indicatif" / "Ce résultat n'est pas un diagnostic médical" disclaimer is present and visible, not buried.
- [ ] "Contacter un professionnel" button — currently a no-op placeholder (see `ContactProfessionalButton.swift`); either wire it to a real, country-appropriate resource before submission or remove the button if it can't be done correctly for launch markets.
- [ ] StoreKit review prompt uses only `@Environment(\.requestReview)` — confirm no custom "Are you enjoying Pillo?" gate was added upstream of it (Apple explicitly rejects apps that filter who sees the system prompt).
- [ ] Account creation (Réglages ▸ CrazyBeeLabs ▸ Créer un compte) opens a website, collects no data in-app, and isn't used to bypass any in-app purchase — confirm still true if IAPs are added later.

## Localization

- [ ] All 5 languages (fr/en/es/de/pt) reviewed by a fluent speaker, not just machine-translated — this codebase's translations were written directly, not run through a separate MT pass, but a native-speaker pass before shipping is still worth doing, especially for the missed-pill and notification strings.
- [ ] `CFBundleLocalizations` in `Info.plist` matches the String Catalog's actual language set.

## Final

- [ ] Archive via `xcodebuild ... archive` (see README "Creating a Production build").
- [ ] Validate the archive in Xcode Organizer before uploading.
- [ ] Prepare App Store screenshots per required device sizes (not automated by this codebase).
- [ ] Read `docs/APP_REVIEW_NOTES.md` and paste the relevant parts into App Store Connect's "Notes for Review" field.
