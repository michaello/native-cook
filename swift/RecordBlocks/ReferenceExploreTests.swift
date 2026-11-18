import XCTest

@MainActor
final class ReferenceExploreTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testExploreFindsThreeVisualBriefs() {
        let app = XCUIApplication()
        let fixtures = [
            (brief: "layered glass", slug: "twist-glass-stack"),
            (brief: "tactile scrubbing", slug: "tape-measure-picker"),
            (brief: "reveal", slug: "cipher-seam")
        ]

        app.launch()
        for fixture in fixtures {
            XCTContext.runActivity(named: "Explore: \(fixture.brief)") { _ in
                search(app, for: fixture.brief)
                XCTAssertTrue(card(fixture.slug, in: app).waitForExistence(timeout: 10))
                app.buttons["reference.clear"].tap()
            }
        }
    }

    func testExactUnillustratedSlugHasSingleResultBoundaries() {
        let app = XCUIApplication()
        app.launch()
        search(app, for: "radar-friend-finder")
        let demo = card("radar-friend-finder", in: app)
        XCTAssertTrue(demo.waitForExistence(timeout: 10))
        demo.tap()

        let control = scrubber(in: app)
        let onlyPosition = "1 of 1 · Radar Friend Finder"
        assertPosition(onlyPosition, on: control)
        tapStep(on: control, next: true)
        XCTAssertEqual(control.value as? String, onlyPosition)
        tapStep(on: control, next: false)
        XCTAssertEqual(control.value as? String, onlyPosition)
    }

    func testSearchPlaybackFollowsDisplayedOrder() {
        let app = XCUIApplication()
        app.launch()
        search(app, for: "constellation")
        let welcome = card("constellation-steps-welcome", in: app)
        let tour = card("morphing-badge-tour", in: app)
        XCTAssertTrue(welcome.waitForExistence(timeout: 10))
        XCTAssertTrue(tour.waitForExistence(timeout: 10))
        let results = [
            (card: welcome, title: "Constellation Steps Welcome"),
            (card: tour, title: "Morphing Badge Tour")
        ].sorted { first, second in
            let firstFrame = first.card.frame
            let secondFrame = second.card.frame
            if firstFrame.maxY <= secondFrame.minY { return true }
            if secondFrame.maxY <= firstFrame.minY { return false }
            return firstFrame.minX < secondFrame.minX
        }
        results[0].card.tap()

        let control = scrubber(in: app)
        let first = "1 of 2 · \(results[0].title)"
        let second = "2 of 2 · \(results[1].title)"
        assertPosition(first, on: control)
        tapStep(on: control, next: true)
        assertPosition(second, on: control)
        tapStep(on: control, next: false)
        assertPosition(first, on: control)
    }

    func testAllAndDirectLaunchUseGlobalOrder() throws {
        let app = XCUIApplication()
        app.launch()
        let filter = app.segmentedControls["blocks.filter"]
        XCTAssertTrue(filter.waitForExistence(timeout: 10))
        filter.buttons["All"].tap()
        let first = card("spectral-capsule-spin", in: app)
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        first.tap()

        let control = scrubber(in: app)
        XCTAssertTrue(control.waitForExistence(timeout: 10))
        let position = try XCTUnwrap(control.value as? String)
        let count = try XCTUnwrap(position.split(separator: " ").dropFirst(2).first.flatMap { Int($0) })
        XCTAssertGreaterThan(count, 12)
        assertPosition("1 of \(count) · Spectral Capsule Spin", on: control)
        tapStep(on: control, next: true)
        assertPosition("2 of \(count) · Thermal Shape Morph", on: control)

        app.terminate()
        app.launchArguments = ["-block", "gold-dune-contours"]
        app.launch()
        assertPosition("3 of \(count) · Gold Dune Contours", on: control)
        tapStep(on: control, next: false)
        assertPosition("2 of \(count) · Thermal Shape Morph", on: control)
    }

    func testRecordingLaunchShowsOnlyTheDemo() {
        let app = XCUIApplication()
        app.launchArguments = ["-block", "gold-dune-contours", "-recording", "1"]
        app.launch()
        XCTAssertTrue(app.staticTexts.matching(identifier: "Dune Wind").firstMatch.waitForExistence(timeout: 10))
        for identifier in ["blocks.scrubber", "blocks.favorite", "blocks.back", "blocks.filter", "reference.search"] {
            XCTAssertFalse(app.descendants(matching: .any).matching(identifier: identifier).firstMatch.exists)
        }
    }

    private func search(_ app: XCUIApplication, for query: String) {
        let field = app.textFields["reference.search"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText(query + "\n")
    }

    private func card(_ slug: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons["block.\(slug)"]
    }

    private func scrubber(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "blocks.scrubber").firstMatch
    }

    private func tapStep(on control: XCUIElement, next: Bool) {
        control.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: next ? 0.8 : 0.2)).tap()
    }

    private func assertPosition(_ value: String, on control: XCUIElement) {
        XCTAssertTrue(control.waitForExistence(timeout: 10))
        let predicate = NSPredicate(format: "value == %@", value)
        expectation(for: predicate, evaluatedWith: control)
        waitForExpectations(timeout: 5)
    }
}
