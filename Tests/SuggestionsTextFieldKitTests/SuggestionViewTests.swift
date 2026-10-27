import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionViewTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    func testHighlightingUpdatesTextImageAndBackgroundAppearance() {
        let view = SuggestionView()

        view.highlighted = true

        XCTAssertEqual(view.backgroundView.material, .selection)
        XCTAssertTrue(view.backgroundView.isEmphasized)
        XCTAssertEqual(view.backgroundView.state, .active)
        XCTAssertEqual(view.label.cell?.backgroundStyle, .emphasized)
        XCTAssertEqual(view.imageView.cell?.backgroundStyle, .emphasized)

        view.highlighted = false

        XCTAssertEqual(view.backgroundView.material, .menu)
        XCTAssertFalse(view.backgroundView.isEmphasized)
        XCTAssertEqual(view.backgroundView.state, .inactive)
        XCTAssertEqual(view.label.cell?.backgroundStyle, .normal)
        XCTAssertEqual(view.imageView.cell?.backgroundStyle, .normal)
    }

    func testAccessibilityExposesCurrentTextWithoutDecorativeChildren() {
        let view = SuggestionView()
        view.label.stringValue = "First result"

        XCTAssertEqual(view.accessibilityLabel(), "First result")
        XCTAssertEqual(view.accessibilityChildren()?.count, 0)

        view.label.stringValue = "Updated result"

        XCTAssertEqual(view.accessibilityLabel(), "Updated result")
    }

    func testResizingGivesAdditionalWidthToLabelWhilePreservingIconSize() {
        let view = SuggestionView()
        view.frame = NSRect(x: 0, y: 0, width: 240, height: 28)
        view.layoutSubtreeIfNeeded()
        let imageFrame = view.imageView.frame
        let labelFrame = view.label.frame
        let backgroundFrame = view.backgroundView.frame

        view.setFrameSize(NSSize(width: 360, height: 28))
        view.layoutSubtreeIfNeeded()

        XCTAssertEqual(view.imageView.frame, imageFrame)
        XCTAssertEqual(view.label.frame.minX, labelFrame.minX, accuracy: 0.001)
        XCTAssertEqual(view.label.frame.width - labelFrame.width, 120, accuracy: 0.001)
        XCTAssertEqual(view.backgroundView.frame.minX, backgroundFrame.minX, accuracy: 0.001)
        XCTAssertEqual(view.backgroundView.frame.width - backgroundFrame.width, 120, accuracy: 0.001)
        XCTAssertEqual(view.label.lineBreakMode, .byTruncatingTail)
    }
}
