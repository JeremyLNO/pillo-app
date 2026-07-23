import Foundation

@MainActor
protocol LocalizationServicing: AnyObject {
    /// The language actually in effect right now (system → supported set →
    /// English fallback → explicit user override, in that priority order).
    var currentLanguage: AppLanguage { get }

    /// Applies `language` immediately (no relaunch) and persists the explicit override.
    /// Passing nil clears the override and reverts to following the system language.
    func setExplicitOverride(_ language: AppLanguage?)
}
