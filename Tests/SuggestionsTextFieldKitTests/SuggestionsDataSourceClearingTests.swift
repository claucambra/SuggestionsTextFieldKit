import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionsDataSourceClearingTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    func testClearingSourceImmediatelyRemovesRowsTrackingAndSelection() throws {
        let controller = SuggestionsWindowController()
        let window = try XCTUnwrap(controller.window)
        window.setFrame(NSRect(x: 100, y: 100, width: 240, height: 100), display: false)
        controller.dataSource = makeDataSource()
        controller.moveDown(nil)
        let oldRow = try XCTUnwrap(controller.viewControllers.first?.view as? SuggestionView)
        XCTAssertTrue(oldRow.highlighted)
        XCTAssertNotNil(controller.selectedSuggestion)

        controller.dataSource = nil

        XCTAssertTrue(controller.viewControllers.isEmpty)
        XCTAssertTrue(window.contentView!.trackingAreas.isEmpty)
        XCTAssertNil(controller.selectedSuggestion)
        XCTAssertNil(oldRow.superview)
        XCTAssertFalse(oldRow.highlighted)
    }

    func testClearingSourceDismissesVisiblePopupAndRemovesFocusObserver() throws {
        let parentWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 200, width: 400, height: 200),
            styleMask: .titled, backing: .buffered, defer: false
        )
        parentWindow.isReleasedWhenClosed = false
        let field = NSTextField(frame: NSRect(x: 20, y: 80, width: 240, height: 24))
        parentWindow.contentView?.addSubview(field)
        parentWindow.orderFront(nil)
        defer { parentWindow.orderOut(nil) }
        let controller = ClearingWindowController()
        controller.window?.setFrame(NSRect(x: 100, y: 200, width: 250, height: 100), display: false)
        controller.parentTextField = field
        controller.dataSource = makeDataSource()
        controller.enableSuggestions()
        let popup = try XCTUnwrap(controller.window as? SuggestionsWindow)
        XCTAssertTrue(popup.isVisible)

        controller.dataSource = nil

        XCTAssertFalse(popup.isVisible)
        XCTAssertNil(popup.parent)
        XCTAssertNil(popup.parentElement)
        XCTAssertTrue(controller.viewControllers.isEmpty)
        let cancelCount = controller.cancelCount
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: parentWindow)
        XCTAssertEqual(controller.cancelCount, cancelCount)
    }

    func testClearedSelectionCannotBeConfirmedThroughDelegate() {
        let delegate = SuggestionsTextFieldDelegate()
        let controller = SuggestionsWindowController()
        controller.window?.setFrame(NSRect(x: 100, y: 100, width: 240, height: 100), display: false)
        let recorder = ClearingConfirmationRecorder()
        delegate.suggestionsDataSource = makeDataSource()
        delegate.suggestionsWindowController = controller
        delegate.confirmationHandler = { recorder.record($0) }
        controller.moveDown(nil)
        XCTAssertNotNil(controller.selectedSuggestion)

        delegate.suggestionsDataSource = nil
        delegate.acceptSuggestion(sender: self)

        XCTAssertEqual(recorder.values.count, 1)
        XCTAssertNil(recorder.values.first ?? nil)
    }

    func testSuggestionsCanBeAssignedAgainAfterImmediateClearing() throws {
        let controller = SuggestionsWindowController()
        controller.window?.setFrame(NSRect(x: 100, y: 100, width: 240, height: 100), display: false)
        controller.dataSource = makeDataSource()
        controller.dataSource = nil
        let replacement = makeDataSource()
        replacement.suggestions = [Suggestion(imageName: "", displayText: "Replacement", data: 2)]

        controller.dataSource = replacement
        controller.moveDown(nil)

        XCTAssertEqual(controller.viewControllers.count, 1)
        XCTAssertEqual(controller.selectedSuggestion?.data as? Int, 2)
        XCTAssertEqual(try XCTUnwrap(controller.window?.contentView).trackingAreas.count, 1)
    }

    private func makeDataSource() -> MockSuggestionsDataSource {
        let source = MockSuggestionsDataSource()
        source.suggestions = [Suggestion(imageName: "", displayText: "Result", data: 1)]
        return source
    }
}

private final class ClearingWindowController: SuggestionsWindowController {
    private(set) var cancelCount = 0

    override func cancelSuggestions() {
        cancelCount += 1
        super.cancelSuggestions()
    }
}

private final class ClearingConfirmationRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValues: [Suggestion?] = []

    var values: [Suggestion?] {
        lock.lock()
        defer { lock.unlock() }
        return storedValues
    }

    func record(_ suggestion: Suggestion?) {
        lock.lock()
        defer { lock.unlock() }
        storedValues.append(suggestion)
    }
}
