import XCTest

@MainActor
final class SpelunkrTVUITests: XCTestCase {
    func testRemoteCanReadPrivacyPolicyAndReturnToGuide() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["watch-live"].waitForExistence(timeout: 60))

        let remote = XCUIRemote.shared
        XCTAssertTrue(app.buttons["live-guide-tab"].hasFocus)
        for _ in 0..<3 { remote.press(.right) }
        XCTAssertTrue(app.buttons["About"].hasFocus)
        remote.press(.select)

        let privacy = app.buttons["Privacy Policy"]
        XCTAssertTrue(privacy.waitForExistence(timeout: 5))
        if !privacy.hasFocus { remote.press(.left) }
        XCTAssertTrue(privacy.hasFocus)
        remote.press(.select)
        XCTAssertTrue(app.staticTexts["Privacy Policy"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Back to About"].hasFocus)

        remote.press(.menu)
        XCTAssertTrue(privacy.waitForExistence(timeout: 5))
        remote.press(.menu)
        XCTAssertTrue(app.buttons["watch-live"].waitForExistence(timeout: 5))
    }

    func testFavoriteSurvivesRelaunch() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let favorite = app.buttons["favorite-toggle"]
        XCTAssertTrue(favorite.waitForExistence(timeout: 60))
        let originalLabel = favorite.label

        XCUIRemote.shared.press(.down)
        XCTAssertTrue(favorite.hasFocus)
        XCUIRemote.shared.press(.select)
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", originalLabel), object: favorite)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed)
        let savedLabel = favorite.label

        app.terminate()
        app.launch()
        XCTAssertTrue(favorite.waitForExistence(timeout: 60))
        XCTAssertEqual(favorite.label, savedLabel)

        // Restore the setting so this test doesn't change an existing preference.
        XCUIRemote.shared.press(.down)
        XCTAssertTrue(favorite.hasFocus)
        XCUIRemote.shared.press(.select)
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", originalLabel), object: favorite)
        XCTAssertEqual(XCTWaiter.wait(for: [restored], timeout: 5), .completed)
    }

    func testRemoteCanOpenSearchAndReturnToLiveGuide() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["watch-live"].waitForExistence(timeout: 60))

        let remote = XCUIRemote.shared
        let liveGuide = app.buttons["live-guide-tab"]
        XCTAssertTrue(liveGuide.hasFocus)
        remote.press(.right)
        XCTAssertTrue(app.buttons["favorites-tab"].hasFocus)
        remote.press(.right)
        XCTAssertTrue(app.buttons["search-button"].hasFocus)
        remote.press(.select)
        XCTAssertTrue(app.textFields["channel-search-field"].waitForExistence(timeout: 5))
        remote.press(.menu)
        XCTAssertTrue(app.buttons["watch-live"].waitForExistence(timeout: 5))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Live guide after remote search navigation"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
