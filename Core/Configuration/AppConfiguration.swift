import Foundation

/// Reads build-time constants that originate in `Config/*.xcconfig` and are threaded
/// through `Info.plist` via `$(VAR)` substitution. Keeping this as a plain struct
/// (not a singleton) makes it trivially fakeable in tests.
struct AppConfiguration: Sendable {
    let appName: String
    let bundleIdentifier: String
    let appStoreID: String
    let appStoreURL: URL
    let appStoreReviewURL: URL
    let oneSignalAppID: String
    let crazyBeeWebsiteURL: URL
    let crazyBeeSupportURL: URL
    let crazyBeeAccountURL: URL
    let crazyBeeCommitmentURL: URL
    let privacyPolicyURL: URL
    let termsURL: URL
    let remoteConfigURL: URL?
    let environment: AppEnvironment

    static let current = AppConfiguration(bundle: .main)

    init(bundle: Bundle) {
        func string(_ key: String, default fallback: String) -> String {
            (bundle.object(forInfoDictionaryKey: key) as? String).flatMap { $0.isEmpty ? nil : $0 } ?? fallback
        }
        func url(_ key: String, default fallback: String) -> URL {
            URL(string: string(key, default: fallback)) ?? URL(string: fallback)!
        }

        appName = string("APP_NAME", default: "Pillo Tracker")
        bundleIdentifier = bundle.bundleIdentifier ?? "company.lno.pillo"
        appStoreID = string("APP_STORE_ID", default: "6794005779")
        appStoreURL = url("APP_STORE_URL", default: "https://apps.apple.com/app/id6794005779")
        appStoreReviewURL = url("APP_STORE_REVIEW_URL", default: "https://apps.apple.com/app/id6794005779?action=write-review")
        oneSignalAppID = string("ONESIGNAL_APP_ID", default: "TODO_ONESIGNAL_APP_ID")
        crazyBeeWebsiteURL = url("CRAZYBEE_WEBSITE_URL", default: "https://crazybeelabs.com/")
        crazyBeeSupportURL = url("CRAZYBEE_SUPPORT_URL", default: "https://crazybeelabs.com/support/")
        crazyBeeAccountURL = url("CRAZYBEE_ACCOUNT_URL", default: "https://crazybeelabs.com/")
        crazyBeeCommitmentURL = url("CRAZYBEE_COMMITMENT_URL", default: "https://www.crazybeelabs.com/commitment")
        privacyPolicyURL = url("PRIVACY_POLICY_URL", default: "https://www.crazybeelabs.com/legal/apps")
        termsURL = url("TERMS_URL", default: "https://www.crazybeelabs.com/legal/apps")
        let remoteConfigString = string("REMOTE_CONFIG_URL", default: "")
        remoteConfigURL = remoteConfigString.isEmpty ? nil : URL(string: remoteConfigString)
        environment = AppEnvironment(bundle: bundle)
    }
}
