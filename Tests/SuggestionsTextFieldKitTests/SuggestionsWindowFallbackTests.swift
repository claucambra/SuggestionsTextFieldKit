import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionsWindowFallbackTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    func testEnablingWithoutDataSourceLeavesRowsEmptyAndDoesNotResizeWindow() throws {
        let controller = SuggestionsWindowController()
        let window = try XCTUnwrap(controller.window)
        window.setFrame(NSRect(x: 100, y: 100, width: 240, height: 100), display: false)
        let originalFrame = window.frame

        controller.enableSuggestions()

        XCTAssertTrue(controller.viewControllers.isEmpty)
        XCTAssertEqual(window.frame, originalFrame)
        XCTAssertFalse(window.isVisible)
    }

    func testClearedDataSourceCanBeRelayoutedWithoutLeavingOldRowsOrSelection() throws {
        let controller = SuggestionsWindowController()
        let window = try XCTUnwrap(controller.window)
        window.setFrame(NSRect(x: 100, y: 100, width: 240, height: 100), display: false)
        controller.dataSource = makeDataSource()
        controller.moveDown(nil)
        let oldRow = try XCTUnwrap(controller.viewControllers.first?.view)
        XCTAssertNotNil(controller.selectedSuggestion)

        controller.dataSource = nil
        controller.enableSuggestions()

        XCTAssertTrue(controller.viewControllers.isEmpty)
        XCTAssertNil(controller.selectedSuggestion)
        XCTAssertNil(oldRow.superview)
        XCTAssertTrue(window.contentView!.trackingAreas.isEmpty)
    }

    func testMissingWindowIgnoresLayoutAndEnableRequests() {
        let controller = SuggestionsWindowController()
        controller.window = nil

        controller.dataSource = makeDataSource()
        controller.enableSuggestions()
        controller.repositionWindow()
        controller.cancelSuggestions()

        XCTAssertNil(controller.window)
        XCTAssertTrue(controller.viewControllers.isEmpty)
    }

    func testReplacementWindowIsNotTreatedAsSuggestionsPopup() {
        let controller = SuggestionsWindowController()
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 240, height: 100),
            styleMask: .borderless, backing: .buffered, defer: true
        )
        controller.window = window
        let originalContent = window.contentView
        let originalFrame = window.frame

        controller.dataSource = makeDataSource()
        controller.enableSuggestions()

        XCTAssertTrue(controller.viewControllers.isEmpty)
        XCTAssertTrue(window.contentView === originalContent)
        XCTAssertEqual(window.frame, originalFrame)
        XCTAssertNil(window.parent)
    }

    func testMissingOrReplacedPopupContentIgnoresLayoutRequests() throws {
        for replacement in [nil, NSView()] as [NSView?] {
            let controller = SuggestionsWindowController()
            let window = try XCTUnwrap(controller.window)
            window.contentView = replacement
            let originalFrame = window.frame

            controller.dataSource = makeDataSource()
            controller.enableSuggestions()

            XCTAssertTrue(controller.viewControllers.isEmpty)
            XCTAssertTrue(window.contentView === replacement)
            XCTAssertEqual(window.frame, originalFrame)
        }
    }

    private func makeDataSource() -> MockSuggestionsDataSource {
        let dataSource = MockSuggestionsDataSource()
        dataSource.suggestions = [Suggestion(imageName: "", displayText: "A result", data: 1)]
        return dataSource
    }
}
