import AppIntents

/// Registers `ConfirmTodayDoseIntent` as a Siri/Shortcuts phrase. Apple's App Shortcuts
/// tooling statically parses `phrases:` at compile time, so — unlike everywhere else in
/// this app — these have to be literal French text inline here rather than String Catalog
/// keys; French is Pillo's primary/development region so this covers the main use case.
struct PilloShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ConfirmTodayDoseIntent(),
            phrases: [
                "J'ai pris ma pilule dans \(.applicationName)",
                "Confirme ma prise de pilule dans \(.applicationName)",
                "Marque ma pilule comme prise dans \(.applicationName)",
            ],
            shortTitle: "intent.confirmDose.shortTitle",
            systemImageName: "checkmark.circle.fill"
        )
    }
}
