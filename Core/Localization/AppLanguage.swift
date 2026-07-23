import Foundation

enum AppLanguage: String, Codable, CaseIterable, Sendable, Identifiable {
    case fr
    case en
    case es
    case de
    case pt

    var id: String { rawValue }

    var locale: Locale { Locale(identifier: rawValue) }

    var nativeName: String {
        switch self {
        case .fr: return "Français"
        case .en: return "English"
        case .es: return "Español"
        case .de: return "Deutsch"
        case .pt: return "Português"
        }
    }
}
