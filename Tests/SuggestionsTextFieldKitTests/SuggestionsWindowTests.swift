import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionsWindowTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    func testWindowUsesPopupAppearanceEvenWhenGivenNormalWindowStyle() {
        let window = SuggestionsWindow(
            contentRect: NSRect(x: 20, y: 30, width: 240, height: 80),
            styleMask: [.titled, .resizable], backing: .buffered, defer: true
        )
        defer { window.orderOut(nil) }

        XCTAssertEqual(window.styleMask, .borderless)
        XCTAssertTrue(window.hasShadow)
        XCTAssertFalse(window.isOpaque)
        XCTAssertEqual(window.backgroundColor, .clear)
        XCTAssertTrue(window.accessibilityIsIgnored())
        XCTAssertNil(window.accessibilityParent())
    }

    func testAccessibilityParentFollowsLogicalParentAndCanBeCleared() {
        let window = SuggestionsWindow(contentRect: .zero, defer: true)
        defer { window.orderOut(nil) }
        let first = NSTextField(labelWithString: "First")
        let second = NSTextField(labelWithString: "Second")
        first.setAccessibilityElement(true)
        second.setAccessibilityElement(true)

        window.parentElement = first
        XCTAssertTrue((window.accessibilityParent() as? NSTextField) === first)

        window.parentElement = second
        XCTAssertTrue((window.accessibilityParent() as? NSTextField) === second)

        window.parentElement = nil
        XCTAssertNil(window.accessibilityParent())
    }
}
