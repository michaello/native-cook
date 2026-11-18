import XCTest

@MainActor
final class ReferenceDraftTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDraftPersistsReordersAndShares() throws {
        let app = isolatedApp()
        app.launch()

        for slug in ["radar-friend-finder", "cipher-seam", "tape-measure-picker"] {
            add(slug, in: app)
        }

        openDraft(in: app)
        let direction = field("draft.direction", in: app)
        direction.tap()
        direction.typeText("Layer smoked glass over a dark surface.")

        let takeaway = field("draft.takeaway.cipher-seam", in: app)
        takeaway.tap()
        takeaway.typeText("Carry the seam glow into the final state.")
        app.buttons["draft.close"].tap()
        openDraft(in: app)

        let radar = app.buttons["draft.open.radar-friend-finder"]
        let cipher = app.buttons["draft.open.cipher-seam"]
        let tape = app.buttons["draft.open.tape-measure-picker"]
        XCTAssertLessThan(radar.frame.minY, cipher.frame.minY)
        XCTAssertLessThan(cipher.frame.minY, tape.frame.minY)

        app.buttons["draft.edit"].tap()
        let radarCell = cell(containing: radar.identifier, in: app)
        let tapeCell = cell(containing: tape.identifier, in: app)
        let dragStart = radarCell.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
        let dragEnd = tapeCell.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.95))
        dragStart.press(forDuration: 0.2, thenDragTo: dragEnd)
        app.buttons["draft.edit"].tap()
        XCTAssertLessThan(cipher.frame.minY, tape.frame.minY)
        XCTAssertLessThan(tape.frame.minY, radar.frame.minY)

        app.terminate()
        app.launch()
        openDraft(in: app)
        XCTAssertEqual(direction.value as? String, "Layer smoked glass over a dark surface.")
        XCTAssertEqual(takeaway.value as? String, "Carry the seam glow into the final state.")
        XCTAssertLessThan(cipher.frame.minY, tape.frame.minY)
        XCTAssertLessThan(tape.frame.minY, radar.frame.minY)

        radar.tap()
        let scrubber = app.descendants(matching: .any).matching(identifier: "blocks.scrubber").firstMatch
        XCTAssertTrue(scrubber.waitForExistence(timeout: 10))
        XCTAssertEqual(scrubber.value as? String, "3 of 3 · Radar Friend Finder")
        let heart = app.buttons["blocks.favorite"]
        let original = heart.label
        heart.tap()
        XCTAssertNotEqual(heart.label, original)
        scrubber.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        expectation(for: NSPredicate(format: "value == %@", "2 of 3 · Tape Measure Picker"), evaluatedWith: scrubber)
        waitForExpectations(timeout: 5)
        app.buttons["blocks.back"].tap()
        openDraft(in: app)
        XCTAssertTrue(radar.waitForExistence(timeout: 5))

        radar.tap()
        XCTAssertTrue(heart.waitForExistence(timeout: 10))
        heart.tap()
        XCTAssertEqual(heart.label, original)
        app.buttons["blocks.back"].tap()
        openDraft(in: app)

        let copy = app.buttons["draft.copy"]
        if !copy.isHittable { app.swipeUp() }
        copy.tap()
        XCTAssertEqual(copy.label, "Markdown copied")
        app.buttons["draft.share"].tap()
        let filename = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Native Cook Reference"))
            .firstMatch
        XCTAssertTrue(filename.waitForExistence(timeout: 10))
    }

    func testMissingDemoCanBeRemovedToEmptyDraft() {
        let app = isolatedApp(seedMissing: true)
        app.launch()
        openDraft(in: app)
        let missing = app.staticTexts["draft.unavailable.unavailable-test-demo"]
        XCTAssertTrue(missing.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["draft.open.unavailable-test-demo"].exists)
        let row = cell(containing: missing.identifier, in: app)
        row.swipeLeft()
        let delete = app.buttons["Delete"].firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()
        XCTAssertTrue(app.staticTexts["No examples yet"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["draft.share"].exists)

        app.terminate()
        app.launch()
        openDraft(in: app)
        XCTAssertTrue(app.staticTexts["No examples yet"].waitForExistence(timeout: 5))
    }

    private func isolatedApp(seedMissing: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-referenceDraftTestID", UUID().uuidString]
        if seedMissing { app.launchArguments += ["-referenceDraftSeedMissing", "1"] }
        return app
    }

    private func field(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func cell(containing id: String, in app: XCUIApplication) -> XCUIElement {
        app.cells.containing(.any, identifier: id).firstMatch
    }

    private func openDraft(in app: XCUIApplication) {
        let draft = app.buttons["gallery.draft"]
        XCTAssertTrue(draft.waitForExistence(timeout: 10))
        draft.tap()
        XCTAssertTrue(app.navigationBars["Reference draft"].waitForExistence(timeout: 10))
    }

    private func add(_ slug: String, in app: XCUIApplication) {
        let clear = app.buttons["reference.clear"]
        if clear.exists { clear.tap() }
        let search = app.textFields["reference.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText(slug + "\n")
        let add = app.buttons["draft.add.\(slug)"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        XCTAssertTrue(add.isEnabled)
        add.tap()
        XCTAssertFalse(add.isEnabled)
        XCTAssertEqual(add.label, "Added to draft")
    }
}
