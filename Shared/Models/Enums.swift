import Foundation

/// Contraception schedule shape. Drives PillScheduleCalculator's day-numbering rules.
enum ScheduleType: String, Codable, CaseIterable, Sendable {
    case days21Active7Stop
    case days24Active4Placebo
    case days28
    case continuous
    case custom
}

enum PillType: String, Codable, CaseIterable, Sendable {
    case combined
    case progestinOnly
    case other
}

/// Lifecycle state of a single scheduled dose.
enum DoseStatus: String, Codable, CaseIterable, Sendable {
    case scheduled
    case takenOnTime
    case takenLate
    case missed
    case skipped
    case placebo
    case unknown
}

enum AppearancePreference: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark
}

enum NotificationPrivacyMode: String, Codable, CaseIterable, Sendable {
    case standard
    case discreet
}

/// How to reconcile the next dose time after a detected timezone/DST change.
/// Additive beyond the spec's literal model field lists — required to implement
/// section 16 (never silently shift the interval between two doses).
enum TimeZoneChangeStrategy: String, Codable, CaseIterable, Sendable {
    case askEachTime
    case alwaysKeepLocalTime
    case alwaysKeepElapsedInterval
}
