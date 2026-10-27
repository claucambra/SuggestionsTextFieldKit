import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionsWindowContentViewTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    func testEmptyContentExposesAnEnabledVerticalListWithoutChildren() {
        let contentView = SuggestionsWindowContentView()

        XCTAssertFalse(contentView.accessibilityIsIgnored())
        XCTAssertTrue(contentView.isAccessibilityEnabled())
        XCTAssertEqual(contentView.accessibilityOrientation(), .vertical)
        XCTAssertEqual(contentView.accessibilityChildren()?.count, 0)
        XCTAssertEqual(contentView.accessibilityVisibleChildren()?.count, 0)
        XCTAssertEqual(contentView.accessibilitySelectedChildren()?.count, 0)
        XCTAssertTrue(contentView.isFlipped)
    }

    func testAccessibilityChildrenIncludeOnlyDirectSuggestionRowsInOrder() {
        let contentView = SuggestionsWindowContentView()
        let first = SuggestionView()
        let second = SuggestionView()
        let decoration = NSView()
        decoration.addSubview(SuggestionView())
        contentView.addSubview(first)
        contentView.addSubview(decoration)
        contentView.addSubview(second)

        XCTAssertEqual(contentView.accessibilityChildren() as? [SuggestionView], [first, second])
        XCTAssertEqual(contentView.accessibilityVisibleChildren() as? [SuggestionView], [first, second])

        first.removeFromSuperview()

        XCTAssertEqual(contentView.accessibilityChildren() as? [SuggestionView], [second])
        XCTAssertEqual(contentView.accessibilityVisibleChildren() as? [SuggestionView], [second])
    }

    func testAccessibilitySelectionTracksHighlightChangesAndRemovedRows() {
        let contentView = SuggestionsWindowContentView()
        let first = SuggestionView()
        let second = SuggestionView()
        let third = SuggestionView()
        [first, second, third].forEach { contentView.addSubview($0) }
        first.highlighted = true
        third.highlighted = true

        XCTAssertEqual(contentView.accessibilitySelectedChildren() as? [SuggestionView], [first, third])

        first.highlighted = false
        second.highlighted = true
        third.removeFromSuperview()

        XCTAssertEqual(contentView.accessibilitySelectedChildren() as? [SuggestionView], [second])

        second.highlighted = false

        XCTAssertEqual(contentView.accessibilitySelectedChildren()?.count, 0)
    }

    func testBackgroundFillsContentWhenResized() throws {
        let contentView = SuggestionsWindowContentView(
            frame: NSRect(x: 0, y: 0, width: 200, height: 80)
        )
        let background = try XCTUnwrap(contentView.subviews.first as? NSVisualEffectView)
        contentView.layoutSubtreeIfNeeded()
        XCTAssertEqual(background.frame, contentView.bounds)

        contentView.setFrameSize(NSSize(width: 320, height: 140))
        contentView.layoutSubtreeIfNeeded()

        XCTAssertEqual(background.frame, contentView.bounds)
        XCTAssertEqual(background.blendingMode, .withinWindow)
        XCTAssertEqual(background.material, .menu)
        XCTAssertEqual(background.state, .active)
    }
}
