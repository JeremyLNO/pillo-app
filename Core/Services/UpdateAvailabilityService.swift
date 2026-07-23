import Foundation

@MainActor
final class UpdateAvailabilityService: UpdateAvailabilityServicing {
    private let remoteConfigURL: URL?
    private let currentVersion: String
    private let currentLanguage: () -> AppLanguage
    private let urlSession: URLSession

    init(
        remoteConfigURL: URL?,
        currentVersion: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0",
        currentLanguage: @escaping () -> AppLanguage,
        urlSession: URLSession = .shared
    ) {
        self.remoteConfigURL = remoteConfigURL
        self.currentVersion = currentVersion
        self.currentLanguage = currentLanguage
        self.urlSession = urlSession
    }

    func checkForUpdate() async -> UpdateCheckResult? {
        guard let remoteConfigURL else { return nil }
        guard let running = SemanticVersion(currentVersion) else { return nil }

        guard let (data, response) = try? await urlSession.data(from: remoteConfigURL),
              let http = response as? HTTPURLResponse, http.statusCode == 200
        else { return nil }

        guard let config = try? JSONDecoder().decode(RemoteUpdateConfig.self, from: data) else { return nil }
        guard let latest = SemanticVersion(config.latestVersion) else { return nil }
        guard let storeURL = URLValidator.validated(config.appStoreURL) else { return nil }

        let minimum = SemanticVersion(config.minimumSupportedVersion)
        let isMandatory = minimum.map { running < $0 } ?? false
        guard isMandatory || running < latest else { return nil }

        let lang = currentLanguage().rawValue
        let message = config.message[lang] ?? config.message["en"] ?? config.message.values.first ?? ""

        return UpdateCheckResult(
            latestVersion: config.latestVersion,
            minimumSupportedVersion: config.minimumSupportedVersion,
            appStoreURL: storeURL,
            message: message,
            isMandatory: isMandatory
        )
    }
}
