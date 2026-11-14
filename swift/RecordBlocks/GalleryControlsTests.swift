import XCTest

@MainActor
final class GalleryControlsTests: XCTestCase {
    func testMoveScrubberAndRememberPosition() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-block", "gold-dune-contours"]
        app.launch()
        let scrubber = app.descendants(matching: .any).matching(identifier: "blocks.scrubber").firstMatch
        XCTAssertTrue(scrubber.waitForExistence(timeout: 10))
        let original = scrubber.frame
        let originalValue = try XCTUnwrap(scrubber.value as? String)
        let targetX = original.midX > app.frame.midX ? 25.0 : app.frame.width - 25
        let start = scrubber.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let target = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: targetX, dy: original.midY + 110))
        start.press(forDuration: 0.7, thenDragTo: target)
        XCTAssertTrue(app.buttons["blocks.favorite"].waitForExistence(timeout: 3))
        XCTAssertEqual(scrubber.frame.midX, targetX, accuracy: 3)
        XCTAssertGreaterThan(scrubber.frame.midY, original.midY + 70)
        XCTAssertEqual(scrubber.value as? String, originalValue)
        let moved = scrubber.frame
        app.terminate()
        app.launch()
        XCTAssertTrue(scrubber.waitForExistence(timeout: 10))
        XCTAssertEqual(scrubber.frame.midX, moved.midX, accuracy: 3)
        XCTAssertEqual(scrubber.frame.midY, moved.midY, accuracy: 3)
        let restore = app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: original.midX, dy: original.midY))
        scrubber.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.5))
            .press(forDuration: 0.7, thenDragTo: restore)
        XCTAssertEqual(scrubber.frame.midX, original.midX, accuracy: 3)
    }

    func testTapAndVerticalScrubStillNavigate() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-block", "gold-dune-contours"]
        app.launch()
        let scrubber = app.descendants(matching: .any).matching(identifier: "blocks.scrubber").firstMatch
        XCTAssertTrue(scrubber.waitForExistence(timeout: 10))
        let firstValue = try XCTUnwrap(scrubber.value as? String)
        scrubber.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8)).tap()
        let changed = NSPredicate(format: "value != %@", firstValue)
        expectation(for: changed, evaluatedWith: scrubber)
        waitForExpectations(timeout: 5)
        let secondValue = try XCTUnwrap(scrubber.value as? String)
        let start = scrubber.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 90)))
        expectation(for: NSPredicate(format: "value != %@", secondValue), evaluatedWith: scrubber)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(app.buttons["blocks.favorite"].isHittable)
    }

    func testFavoritePersistsAndAppearsInGallery() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-block", "gold-dune-contours"]
        app.launch()
        let heart = app.buttons["blocks.favorite"]
        XCTAssertTrue(heart.waitForExistence(timeout: 10))
        let wasFavorite = heart.label == "Remove from favorites"
        let control = app.descendants(matching: .any).matching(identifier: "blocks.scrubber").firstMatch
        let selected = try XCTUnwrap(control.value as? String)
        XCTAssertEqual(heart.frame.width, 44, accuracy: 1)
        if !wasFavorite { heart.tap() }
        expectation(for: NSPredicate(format: "label == %@", "Remove from favorites"), evaluatedWith: heart)
        waitForExpectations(timeout: 5)
        XCTAssertEqual(control.value as? String, selected)
        app.terminate()
        app.launch()
        XCTAssertTrue(heart.waitForExistence(timeout: 10))
        XCTAssertEqual(heart.label, "Remove from favorites")
        // Tapping outside the controls must leave the current demo selected.
        let scrubber = app.descendants(matching: .any).matching(identifier: "blocks.scrubber").firstMatch
        let value = try XCTUnwrap(scrubber.value as? String)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7)).tap()
        XCTAssertEqual(scrubber.value as? String, value)
        app.terminate()
        app.launchArguments = []
        app.launch()
        let filter = app.segmentedControls["blocks.filter"]
        XCTAssertTrue(filter.waitForExistence(timeout: 10))
        filter.buttons["Favorites"].tap()
        let demo = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Gold Dune Contours")).firstMatch
        XCTAssertTrue(demo.waitForExistence(timeout: 5))
        demo.tap()
        XCTAssertTrue(heart.waitForExistence(timeout: 10))
        if !wasFavorite {
            heart.tap()
            XCTAssertEqual(heart.label, "Add to favorites")
        }
    }
}
