# Notes for the App Review team

Paste the relevant sections below into App Store Connect's "Notes for Review" field, or attach as-is.

## No account required

Pillo Tracker works fully without creating an account. All reminder data is stored locally on-device (SwiftData); nothing is required to sign up, sign in, or use any core feature. A "Créer un compte" row exists in Réglages ▸ CrazyBeeLabs — it opens `https://crazybeelabs.com/` in the system browser (or in-app web view) and is entirely optional; it does not gate any feature.

## Health data handling

The app tracks self-reported contraceptive-pill intake and (optionally) menstrual/symptom data. This data:
- Never leaves the device except as explicitly initiated by the user (the "Exporter mes données" and history CSV/PDF export rows, both of which hand off to the system share sheet — no automatic upload anywhere).
- Is never used for advertising, tracking, or analytics.
- Is not linked to any account or identity (there is none).

Full detail in `docs/DATA_POLICY.md` if your review needs it.

## Missed-pill assistant is not a diagnostic tool

The "Oubli" tab asks a few structured questions (delay, pills missed, week in pack, recent intercourse) and always returns the same generic, clearly-labeled non-diagnostic guidance: *"Consultez la notice de votre pilule ou contactez rapidement un pharmacien, une sage-femme ou un médecin."* No AI-generated or unreviewed medical content is shown anywhere in the app — see `docs/MEDICAL_RULE_GUIDE.md` for the (currently unpopulated) architecture that would carry real medically-reviewed guidance in a future version.

## Push notifications (OneSignal)

If `ONESIGNAL_APP_ID` is configured for this build: OneSignal is used only for optional update-availability and CrazyBeeLabs announcement pushes, opted into separately in Réglages ▸ Notifications CrazyBeeLabs. It is never used for the core pill reminder (that's 100% local `UNUserNotificationCenter` scheduling) and never receives any health-related data — only app version, language, platform, and consent flags.

## Face ID / PIN

`NSFaceIDUsageDescription` explains Face ID is used solely to lock the app. An independent PIN code (Réglages ▸ Confidentialité ▸ Code PIN) is available as a fallback/alternative, hashed and stored in Keychain — never in plaintext, never transmitted.

## Demo account / test data

No login is required to review the app. To see a populated demo state quickly (optional — real onboarding also works from a blank state):
- If testing via source: launch with the `-demoSeed` argument (see README "Demo data").
- Via TestFlight/App Store build: complete the (≈60-second) onboarding flow with any pill schedule — no account, no external service required.

## Third-party SDK

`OneSignal-XCFramework` (SPM, https://github.com/OneSignal/OneSignal-XCFramework) is the only third-party dependency. It's used exactly as described above; disable it entirely by leaving `ONESIGNAL_APP_ID` unset — the app is fully functional without it.
