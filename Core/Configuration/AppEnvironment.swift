import Foundation

enum AppEnvironment: String, Sendable {
    case development
    case staging
    case production

    init(bundle: Bundle) {
        let raw = bundle.object(forInfoDictionaryKey: "APP_ENVIRONMENT") as? String
        self = AppEnvironment(rawValue: raw?.lowercased() ?? "") ?? .development
    }
}
