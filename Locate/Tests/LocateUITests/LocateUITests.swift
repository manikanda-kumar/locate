import XCTest

final class LocateUITests: XCTestCase {
    
    // Creates the target application for UI testing without hardcoding a bundle identifier.
    // Prefer setting the test scheme's Host Application to the app target. Alternatively, set an
    // environment variable `UI_TEST_APP_BUNDLE_ID` in the Test action to the app's bundle identifier.
    // When the env var is present, the test will launch by bundle identifier; otherwise it will
    // fall back to `XCUIApplication()` which requires a configured Host Application.
    @MainActor
    private func makeApp() -> XCUIApplication? {
        let env = ProcessInfo.processInfo.environment
        if let bundleID = env["UI_TEST_APP_BUNDLE_ID"], !bundleID.isEmpty {
            return XCUIApplication(bundleIdentifier: bundleID)
        }
        // If a Host Application is configured, XCUIApplication() will work; otherwise, return nil to allow caller to skip
        return XCUIApplication()
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    @MainActor
    func testAppLaunchAndBasicUI() throws {
        let maybeApp = makeApp()
        // If no host application is configured and no bundle id is provided, skip with guidance.
        try XCTSkipIf(maybeApp == nil, "No target application configured. Set the test scheme's Host Application to the app target, or set the UI_TEST_APP_BUNDLE_ID environment variable to the app's bundle identifier.")
        let app = maybeApp!
        app.launch()

        // Assert the window exists
        let window = app.windows["Locate"]
        XCTAssertTrue(window.exists, "The main window should exist")

        // Use the accessibility identifier we just added
        let searchField = window.textFields["SearchField"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5.0), "Search text field should be present")

        searchField.click()
        searchField.typeText("test query")

        XCTAssertEqual(searchField.value as? String, "test query")

        // Check for the menus instead of buttons, as we saw they are Pickers in the code
        let typeFilter = window.popUpButtons["TypeFilter"]
        XCTAssertTrue(typeFilter.exists, "Type filter should exist")

        typeFilter.click()
        // Accessing menu items in a popup button
        if app.menuItems["Documents"].waitForExistence(timeout: 2.0) {
            app.menuItems["Documents"].click()
        } else {
            XCTFail("'Documents' menu item not found in TypeFilter pop-up")
        }
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            let env = ProcessInfo.processInfo.environment
            let bundleID = env["UI_TEST_APP_BUNDLE_ID"]
            let app: XCUIApplication?
            if let id = bundleID, !id.isEmpty {
                app = XCUIApplication(bundleIdentifier: id)
            } else {
                // Fall back to default app if Host Application is configured; otherwise, skip.
                app = XCUIApplication()
            }
            try XCTSkipIf(app == nil, "No target application configured. Set Host Application or UI_TEST_APP_BUNDLE_ID.")
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                app!.launch()
            }
        }
    }
}
