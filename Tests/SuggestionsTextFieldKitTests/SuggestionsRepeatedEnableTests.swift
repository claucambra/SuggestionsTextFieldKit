import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionsRepeatedEnableTests: XCTestCase {
    private var controller: RepeatedEnableController!
    private var parentWindow: NSWindow!
    private var textField: NSTextField!

    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
        parentWindow = RepeatedEnableWindow(
            contentRect: NSRect(x: 100, y: 200, width: 480, height: 240),
            styleMask: .titled, backing: .buffered, defer: false
        )
        parentWindow.isReleasedWhenClosed = false
        textField = NSTextField(frame: NSRect(x: 30, y: 120, width: 260, height: 24))
        parentWindow.contentView?.addSubview(textField)
        parentWindow.orderFront(nil)
        parentWindow.makeFirstResponder(nil)
        controller = RepeatedEnableController()
        controller.window?.setFrame(NSRect(x: 100, y: 200, width: 270, height: 100), display: false)
        controller.parentTextField = textField
    }

    override func tearDown() {
        controller?.cancelSuggestions()
        parentWindow.orderOut(nil)
        controller = nil
        textField = nil
        parentWindow = nil
        super.tearDown()
    }

    func testRepeatedEnableInstallsOnlyOneFocusObserver() throws {
        controller.enableSuggestions()
        controller.enableSuggestions()
        controller.enableSuggestions()

        postParentLostFocus()

        XCTAssertEqual(controller.cancelCount, 1)
        XCTAssertFalse(try XCTUnwrap(controller.window).isVisible)
        postParentLostFocus()
        XCTAssertEqual(controller.cancelCount, 1)
    }

    func testRepeatedEnableInstallsOnlyOneMouseMonitor() throws {
        controller.enableSuggestions()
        controller.enableSuggestions()
        controller.enableSuggestions()

        sendMouseDownWithoutWindow()

        XCTAssertEqual(controller.cancelCount, 1)
        XCTAssertFalse(try XCTUnwrap(controller.window).isVisible)
        sendMouseDownWithoutWindow()
        XCTAssertEqual(controller.cancelCount, 1)
    }

    func testRepeatedEnableStillRefreshesRowsSelectionAndPosition() throws {
        let dataSource = MockSuggestionsDataSource()
        dataSource.suggestions = [Suggestion(imageName: "", displayText: "Original", data: 1)]
        controller.dataSource = dataSource
        controller.enableSuggestions()
        controller.moveDown(nil)
        let oldRow = try XCTUnwrap(controller.viewControllers.first?.view as? SuggestionView)
        XCTAssertTrue(oldRow.highlighted)
        let oldWindowFrame = try XCTUnwrap(controller.window).frame
        textField.frame.origin.x += 25
        textField.frame.size.width += 60
        dataSource.suggestions = [
            Suggestion(imageName: "", displayText: "Updated first", data: 2),
            Suggestion(imageName: "", displayText: "Updated second", data: 3),
        ]

        controller.enableSuggestions()

        let window = try XCTUnwrap(controller.window)
        XCTAssertTrue(window.isVisible)
        XCTAssertEqual(window.frame.minX, oldWindowFrame.minX + 25, accuracy: 0.01)
        XCTAssertEqual(window.frame.width, oldWindowFrame.width + 60, accuracy: 0.01)
        XCTAssertEqual(controller.viewControllers.count, 2)
        XCTAssertEqual((controller.viewControllers[0].representedObject as? Suggestion)?.data as? Int, 2)
        XCTAssertEqual((controller.viewControllers[1].representedObject as? Suggestion)?.data as? Int, 3)
        XCTAssertNil(controller.selectedSuggestion)
        XCTAssertNil(oldRow.superview)
        XCTAssertFalse(oldRow.highlighted)
        XCTAssertEqual(controller.cancelCount, 0)
    }

    func testCancelAndRepeatedReenableRestoreOneSetOfDismissalHandlers() throws {
        controller.enableSuggestions()
        controller.enableSuggestions()
        controller.cancelSuggestions()
        XCTAssertEqual(controller.cancelCount, 1)
        postParentLostFocus()
        sendMouseDownWithoutWindow()
        XCTAssertEqual(controller.cancelCount, 1)

        controller.enableSuggestions()
        controller.enableSuggestions()
        XCTAssertTrue(try XCTUnwrap(controller.window).isVisible)
        sendMouseDownWithoutWindow()

        XCTAssertEqual(controller.cancelCount, 2)
        XCTAssertFalse(try XCTUnwrap(controller.window).isVisible)
        postParentLostFocus()
        sendMouseDownWithoutWindow()
        XCTAssertEqual(controller.cancelCount, 2)
    }

    func testRepeatedNonemptyTextChangesDoNotLeaveDismissalHandlersAfterEditingEnds() {
        let delegate = SuggestionsTextFieldDelegate()
        let editingField = RepeatedEnableEditingField()
        let dataSource = MockSuggestionsDataSource()
        delegate.targetTextField = textField
        delegate.suggestionsDataSource = dataSource
        delegate.suggestionsWindowController = controller
        let notification = Notification(name: NSControl.textDidChangeNotification, object: editingField)

        for input in ["s", "se", "sea", "search"] {
            editingField.editor.string = input
            delegate.controlTextDidChange(notification)
        }
        XCTAssertEqual(dataSource.inputString, "search")
        delegate.controlTextDidEndEditing(notification)
        XCTAssertEqual(controller.cancelCount, 1)

        postParentLostFocus()
        sendMouseDownWithoutWindow()

        XCTAssertEqual(controller.cancelCount, 1)
    }

    func testRepeatedEnableDoesNotRetainControllerAfterOwnerReleasesIt() throws {
        // Drain temporary AppKit ownership before checking the controller's lifetime.
        controller = nil
        weak var releasedController: SuggestionsWindowController?
        var retainedPopup: NSWindow?
        autoreleasepool {
            let owner = RepeatedEnableController()
            owner.window?.setFrame(NSRect(x: 100, y: 200, width: 270, height: 100), display: false)
            owner.parentTextField = textField
            owner.enableSuggestions()
            owner.enableSuggestions()
            releasedController = owner
            retainedPopup = owner.window
        }

        let popup = try XCTUnwrap(retainedPopup)
        XCTAssertNil(releasedController)
        XCTAssertFalse(popup.isVisible)
        XCTAssertNil(popup.parent)
        XCTAssertNil((popup as? SuggestionsWindow)?.parentElement)
        // Delivery after release also exercises cleanup without invoking a dead controller.
        postParentLostFocus()
        sendMouseDownWithoutWindow()
    }

    func testReparentingSameTextFieldReplacesWindowDismissalHandlers() throws {
        let newParent = RepeatedEnableWindow(
            contentRect: NSRect(x: 650, y: 200, width: 480, height: 240),
            styleMask: .titled, backing: .buffered, defer: false
        )
        newParent.isReleasedWhenClosed = false
        newParent.orderFront(nil)
        defer { newParent.orderOut(nil) }
        controller.enableSuggestions()
        let popup = try XCTUnwrap(controller.window)
        XCTAssertTrue(popup.parent === parentWindow)

        newParent.contentView?.addSubview(textField)
        newParent.makeFirstResponder(nil)
        controller.enableSuggestions()

        XCTAssertEqual(controller.cancelCount, 1)
        XCTAssertTrue(popup.parent === newParent)
        XCTAssertTrue(popup.isVisible)
        postParentLostFocus()
        XCTAssertEqual(controller.cancelCount, 1)
        XCTAssertTrue(popup.isVisible)

        let point = NSPoint(x: textField.frame.midX, y: textField.frame.midY)
        XCTAssertTrue(newParent.contentView?.hitTest(point) === textField)
        let fieldClick = RepeatedEnableMouseEvent()
        fieldClick.targetWindow = newParent
        fieldClick.point = point
        NSApplication.shared.sendEvent(fieldClick)
        XCTAssertEqual(controller.cancelCount, 1)
        XCTAssertTrue(popup.isVisible)

        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: newParent)
        XCTAssertEqual(controller.cancelCount, 2)
        XCTAssertFalse(popup.isVisible)
        postParentLostFocus()
        sendMouseDownWithoutWindow()
        XCTAssertEqual(controller.cancelCount, 2)
    }

    func testEnablingAfterTextFieldIsRemovedFromWindowCleansUpPopupAndHandlers() throws {
        controller.enableSuggestions()
        let popup = try XCTUnwrap(controller.window as? SuggestionsWindow)

        textField.removeFromSuperview()
        controller.enableSuggestions()

        XCTAssertEqual(controller.cancelCount, 1)
        XCTAssertFalse(popup.isVisible)
        XCTAssertNil(popup.parent)
        XCTAssertNil(popup.parentElement)
        postParentLostFocus()
        sendMouseDownWithoutWindow()
        XCTAssertEqual(controller.cancelCount, 1)
    }

    func testReenablingExternallyHiddenPopupShowsItWithOneSetOfHandlers() throws {
        controller.enableSuggestions()
        let popup = try XCTUnwrap(controller.window)
        popup.orderOut(nil)
        XCTAssertFalse(popup.isVisible)

        controller.enableSuggestions()

        XCTAssertTrue(popup.isVisible)
        XCTAssertTrue(popup.parent === parentWindow)
        XCTAssertEqual(controller.cancelCount, 1)
        postParentLostFocus()
        XCTAssertEqual(controller.cancelCount, 2)
        XCTAssertFalse(popup.isVisible)
        postParentLostFocus()
        sendMouseDownWithoutWindow()
        XCTAssertEqual(controller.cancelCount, 2)
    }

    private func postParentLostFocus() {
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: parentWindow)
    }

    private func sendMouseDownWithoutWindow() {
        NSApplication.shared.sendEvent(RepeatedEnableMouseEvent())
    }
}

private final class RepeatedEnableController: SuggestionsWindowController {
    private(set) var cancelCount = 0

    override func cancelSuggestions() {
        cancelCount += 1
        super.cancelSuggestions()
    }
}

private final class RepeatedEnableEditingField: NSTextField {
    let editor = NSTextView()
    override func currentEditor() -> NSText? { editor }
}

private final class RepeatedEnableMouseEvent: NSEvent {
    var targetWindow: NSWindow?
    var point: NSPoint = .zero

    override var type: NSEvent.EventType { .leftMouseDown }
    override var window: NSWindow? { targetWindow }
    override var locationInWindow: NSPoint { point }
}

private final class RepeatedEnableWindow: NSWindow {
    override func sendEvent(_ event: NSEvent) {}
}
