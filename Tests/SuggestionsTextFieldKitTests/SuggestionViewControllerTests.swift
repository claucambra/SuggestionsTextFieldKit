import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionViewControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    func testAssigningSuggestionLoadsAndPopulatesView() throws {
        let controller = SuggestionViewController()
        let image = NSImage(size: NSSize(width: 16, height: 16))
        let imageName = NSImage.Name(UUID().uuidString)
        XCTAssertTrue(image.setName(imageName))
        defer { image.setName(nil) }
        XCTAssertFalse(controller.isViewLoaded)

        controller.representedObject = Suggestion(
            imageName: imageName, displayText: "A result", data: 42
        )

        let view = try XCTUnwrap(controller.suggestionView)
        XCTAssertTrue(controller.isViewLoaded)
        XCTAssertEqual(view.label.stringValue, "A result")
        XCTAssertTrue(view.imageView.image === image)
        XCTAssertEqual(view.accessibilityLabel(), "A result")
        XCTAssertEqual((controller.representedObject as? Suggestion)?.data as? Int, 42)
    }

    func testReplacingSuggestionUpdatesExistingViewAndClearsMissingImage() throws {
        let controller = SuggestionViewController()
        let image = NSImage(size: NSSize(width: 16, height: 16))
        let imageName = NSImage.Name(UUID().uuidString)
        XCTAssertTrue(image.setName(imageName))
        defer { image.setName(nil) }
        controller.representedObject = Suggestion(
            imageName: imageName, displayText: "First", data: 1
        )
        let originalView = try XCTUnwrap(controller.suggestionView)
        XCTAssertNotNil(originalView.imageView.image)

        controller.representedObject = Suggestion(
            imageName: UUID().uuidString, displayText: "Second", data: 2
        )

        XCTAssertTrue(controller.suggestionView === originalView)
        XCTAssertEqual(originalView.label.stringValue, "Second")
        XCTAssertNil(originalView.imageView.image)
        XCTAssertEqual(originalView.accessibilityLabel(), "Second")
    }

    func testUnsupportedRepresentedObjectsLeaveDisplayedSuggestionIntact() throws {
        let controller = SuggestionViewController()
        controller.representedObject = Suggestion(
            imageName: "", displayText: "Keep this result", data: "payload"
        )
        let view = try XCTUnwrap(controller.suggestionView)

        controller.representedObject = "An unrelated object"
        XCTAssertEqual(view.label.stringValue, "Keep this result")

        controller.representedObject = nil
        XCTAssertEqual(view.label.stringValue, "Keep this result")
        XCTAssertTrue(controller.suggestionView === view)
    }

    func testSuggestionAssignmentWithCustomViewDoesNotReplaceIt() {
        let controller = SuggestionViewController()
        let customView = NSView()
        controller.view = customView

        controller.representedObject = Suggestion(
            imageName: "", displayText: "A result", data: 1
        )

        XCTAssertTrue(controller.view === customView)
        XCTAssertNil(controller.suggestionView)
    }

    func testDecodingUnsupportedArchivedControllerFailsWithoutTrapping() throws {
        let archive = try NSKeyedArchiver.archivedData(
            withRootObject: SuggestionViewController(), requiringSecureCoding: false
        )
        let decoder = try NSKeyedUnarchiver(forReadingFrom: archive)
        decoder.requiresSecureCoding = false
        decoder.decodingFailurePolicy = .setErrorAndReturn
        defer { decoder.finishDecoding() }

        XCTAssertNil(decoder.decodeObject(forKey: NSKeyedArchiveRootObjectKey))
    }
}
