import XCTest

final class PilloUITests: XCTestCase {
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launchArguments += ["-demoSeed"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    func testTabsRenderAndCaptureScreenshots() {
        let app = XCUIApplication()
        app.launchArguments += ["-demoSeed"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        func snapshot(_ name: String) {
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        snapshot("01-Home")

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        // Positional index, not accessibility label lookup — tab labels are localized
        // (String Catalog resolves "tab.blister" to "Pack"/"Plaquette"/etc.), so the raw
        // key never matches the rendered accessibility text.
        let names = ["02-Blister", "03-MissedPill", "04-History", "05-Settings"]
        for (offset, name) in names.enumerated() {
            let index = offset + 1
            guard tabBar.buttons.count > index else { continue }
            tabBar.buttons.element(boundBy: index).tap()
            _ = app.wait(for: .runningForeground, timeout: 3)
            snapshot(name)
        }
    }

    /// Covers the 4 additions on top of the original spec: adaptive-reminder toggle,
    /// "Add to Siri" entry point, and the trusted-contact section all render in Settings.
    func testNewSettingsRowsRender() {
        let app = XCUIApplication()
        app.launchArguments += ["-demoSeed"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        tabBar.buttons.element(boundBy: 4).tap()
        _ = app.wait(for: .runningForeground, timeout: 3)

        let adaptiveToggle = app.switches["Adaptive reminder"]
        XCTAssertTrue(adaptiveToggle.waitForExistence(timeout: 5))
        app.swipeUp()

        XCTAssertTrue(app.buttons["Add to Siri"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Trusted contact"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["Alert someone if a dose stays unconfirmed"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "settings-new-rows"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Produces the App Store listing screenshots (`-screenshotSeed`, richer history than
    /// the `-demoSeed` fixture). Unlike testTabsRenderAndCaptureScreenshots — which taps by
    /// index and captures immediately, fine for regression but not for a store listing —
    /// this one dismisses the notification prompt, waits for each transition to settle and
    /// asserts it is on the expected screen before shooting.
    func testCaptureAppStoreScreenshots() {
        let app = XCUIApplication()
        app.launchArguments += ["-screenshotSeed"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // The permission alert belongs to SpringBoard, not to the app, so it has to be
        // queried there — otherwise it sits on top of the first screenshot.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 8) {
            allow.tap()
        }

        func shoot(_ name: String, expecting title: String) {
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 8), "\(name): \(title) introuvable")
            Thread.sleep(forTimeInterval: 1.2) // let the tab transition settle
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        shoot("store-01-Home", expecting: "Pillo Tracker")

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        let screens = [(1, "store-02-Pack", "Pack"), (2, "store-03-Missed", "Missed pill"),
                       (3, "store-04-Tracking", "Tracking"), (4, "store-05-Settings", "Settings")]
        for (index, name, title) in screens {
            tabBar.buttons.element(boundBy: index).tap()
            shoot(name, expecting: title)
        }
    }

    func testConfirmDoseReflectsAcrossScreens() {
        let app = XCUIApplication()
        app.launchArguments += ["-demoSeed"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        func snapshot(_ name: String) {
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        let confirmButton = app.buttons["I took my pill"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5), "Confirm button should exist on Home")
        confirmButton.tap()

        let confirmedLabel = app.staticTexts["Dose confirmed"]
        XCTAssertTrue(confirmedLabel.waitForExistence(timeout: 5), "Home should show confirmed state after tapping")
        snapshot("confirmed-home")

        let tabBar = app.tabBars.firstMatch
        tabBar.buttons.element(boundBy: 1).tap() // Pack
        _ = app.wait(for: .runningForeground, timeout: 3)
        snapshot("confirmed-pack")
        XCTAssertTrue(app.staticTexts["Taken"].waitForExistence(timeout: 5))
    }

    /// Full onboarding walk-through on a genuinely fresh store (spec section 32: "Une
    /// utilisatrice peut configurer sa plaquette"), explicitly refusing the system
    /// notification prompt along the way — the app must stay fully usable afterward
    /// (spec section 9: "l'application reste utilisable lorsque l'autorisation est
    /// refusée").
    func testOnboardingCompletesAndRefusesNotifications() {
        let app = XCUIApplication()
        app.launchArguments += ["-freshInstall"]

        let interruption = addUIInterruptionMonitor(withDescription: "Notification permission") { alert in
            let denyButton = alert.buttons["Don’t Allow"].exists ? alert.buttons["Don’t Allow"] : alert.buttons["Don't Allow"]
            if denyButton.exists {
                denyButton.tap()
                return true
            }
            return false
        }
        defer { removeUIInterruptionMonitor(interruption) }

        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // The one-time "Pillo is free" commitment screen precedes onboarding on a
        // genuinely fresh store (gated by `UserPreferences.hasSeenCommitmentScreen`).
        let commitmentContinue = app.buttons["Continue"]
        XCTAssertTrue(commitmentContinue.waitForExistence(timeout: 5))
        commitmentContinue.tap()

        let getStarted = app.buttons["Get started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()

        let nameField = app.textFields["My pill"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Ma pilule de test")

        app.buttons["Continue"].tap()

        let enableNotifications = app.buttons["Enable notifications"]
        XCTAssertTrue(enableNotifications.waitForExistence(timeout: 5))
        enableNotifications.tap()
        app.tap() // gives the interruption monitor a chance to fire on the system alert

        let continueAfterDenial = app.buttons["Continue"]
        XCTAssertTrue(continueAfterDenial.waitForExistence(timeout: 5))
        continueAfterDenial.tap()

        let finish = app.buttons["Finish"]
        XCTAssertTrue(finish.waitForExistence(timeout: 5))
        finish.tap()

        // Onboarding is done — Home should render normally, proving the app stays fully
        // usable even though notification permission was refused.
        let confirmButton = app.buttons["I took my pill"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
    }

    func testDarkModeRenders() {
        let app = XCUIApplication()
        app.launchArguments += ["-demoSeed", "-UIUserInterfaceStyle", "Dark"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.buttons["I took my pill"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "dark-mode-home"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testDynamicTypeAccessibilityXXLRenders() {
        let app = XCUIApplication()
        app.launchArguments += ["-demoSeed", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        // Just needs to still be alive and showing something recognizable at this scale —
        // exact layout at accessibility sizes isn't asserted, only that nothing crashed.
        XCTAssertTrue(app.otherElements.firstMatch.waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "dynamic-type-xxl-home"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testLanguageSwitchAppliesImmediately() {
        let app = XCUIApplication()
        app.launchArguments += ["-demoSeed"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let tabBar = app.tabBars.firstMatch
        tabBar.buttons.element(boundBy: 4).tap() // Settings
        _ = app.wait(for: .runningForeground, timeout: 3)

        // Match by label across any element type (StaticText vs Button is ambiguous here
        // depending on how SwiftUI merges the row's accessibility elements) rather than
        // assuming a specific control type.
        let francais = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Français")).firstMatch
        // The Langue section sits below the fold in a long Form, and SwiftUI's Form
        // lazily materializes far-off-screen rows — scroll incrementally and stop the
        // moment it's found, rather than a fixed swipe count that can overshoot past it.
        var foundLanguageRow = false
        for _ in 0..<12 {
            if francais.exists {
                foundLanguageRow = true
                break
            }
            app.swipeUp(velocity: .slow)
        }
        XCTAssertTrue(foundLanguageRow, "Could not scroll to the Français row")
        francais.tap()

        // French renders immediately, no relaunch — the Réglages nav title switches
        // from "Settings" to "Réglages" right away.
        XCTAssertTrue(app.navigationBars["Réglages"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "settings-french"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
