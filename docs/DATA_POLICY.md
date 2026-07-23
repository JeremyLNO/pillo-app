# Data handling policy

This is the internal reference for what Pillo stores, where, why, and for how long — the source material for the published Privacy Policy page (`PRIVACY_POLICY_URL`), not the public-facing page itself.

## What's stored, and where

All of the following live **only** in the on-device SwiftData store (`PersistenceController`, an encrypted-at-rest SQLite database under the app's sandboxed container, protected by iOS Data Protection). Nothing here is synced to iCloud, sent to a CrazyBeeLabs server, or included in a backup unless the user's device backup itself is (standard iOS/iCloud device backup behavior, outside this app's control):

- `PillProfile` — pill name, brand, schedule, intake time.
- `DoseEvent` — every scheduled/confirmed/missed dose, with timestamps.
- `StockEntry` — pack count, prescription/appointment dates.
- `SymptomEntry` — optional, user-initiated symptom logs.
- `NotificationPreferences`, `UserPreferences` — app settings, including the biometric-lock and discreet-mode flags themselves.

A separate Keychain entry (`AppLockService`/`KeychainStore`, `.afterFirstUnlockThisDeviceOnly`) holds only the SHA-256 hash of an optional app PIN — never the PIN itself, never any health data.

## What leaves the device, and to whom

- **OneSignal** (only if the user opts in to update or marketing notifications in Réglages): receives a push-subscription ID plus the technical tags listed in `docs/ONESIGNAL_SETUP.md` §5 — app version, language, platform, environment, and the two consent booleans. Audited exhaustively: `OneSignalService.swift` is the only file that imports the SDK, and `syncTechnicalTags`'s parameter list is the entire set of data ever sent.
- **`REMOTE_CONFIG_URL`** (if configured): the app makes a plain `GET` request with no user data attached, to check for an available update.
- Nothing else. No analytics SDK is integrated (`AnalyticsService`'s only implementation is `NoOpAnalyticsService` — see Phase 2+ if one is ever added, and if so it must never receive a health-data field).

## Retention & deletion

- All data persists until the user deletes it. Réglages ▸ Confidentialité ▸ "Supprimer toutes les données locales" (`ConfidentialiteSection.deleteAllData()`) deletes every `PillProfile`, `DoseEvent`, `SymptomEntry`, `StockEntry`, and `CustomScheduleDay`, removes the app PIN from Keychain, and resets onboarding — verifiably complete because it re-enters the onboarding flow rather than leaving stale state.
- Uninstalling the app removes the SwiftData store and Keychain entries (Keychain entries with `.afterFirstUnlockThisDeviceOnly` are removed on app deletion, not just device restart).
- There is no server-side copy to separately delete, because there is no server-side copy.

## User rights (GDPR-style, even though this is a local-only app)

- **Access/portability**: Réglages ▸ Confidentialité ▸ "Exporter mes données" produces a complete JSON export (`DataExportService`) of every model above, shareable via the system share sheet. History has a separate, narrower CSV/PDF export (`HistoryExportService`) intended for sharing a dose-history summary with a clinician.
- **Erasure**: see Retention & deletion above.
- **Consent**: notification permission (local), push permission (OneSignal), and the two OneSignal consent toggles are each requested/tracked independently — never bundled into one blanket "accept all."

## Explicitly out of scope for v1

- No account system, so no server-side profile to protect or breach.
- No health data ever leaves the device via any channel described above.
- No iCloud sync of the SwiftData store (would require explicit legal review + a CloudKit container audit before enabling — not something to flip on without going back through this document).
