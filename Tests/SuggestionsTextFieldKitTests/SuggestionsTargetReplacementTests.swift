import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionsTargetReplacementTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    func testReplacingTargetDetachesOwnedWiringFromRetainedOldField() {
        let delegate = SuggestionsTextFieldDelegate()
        let oldField = NSTextField()
        delegate.targetTextField = oldField
        let newField = NSTextField()

        delegate.targetTextField = newField

        XCTAssertNil(oldField.delegate)
        XCTAssertNil(oldField.target)
        XCTAssertNil(oldField.action)
        XCTAssertTrue(newField.delegate === delegate)
        XCTAssertTrue(newField.target === delegate)
        XCTAssertEqual(newField.action, #selector(SuggestionsTextFieldDelegate.acceptSuggestion(sender:)))
    }

    func testClearingTargetDetachesOwnedWiringAndControllerParent() {
        let delegate = SuggestionsTextFieldDelegate()
        let controller = TargetReplacementController()
        delegate.suggestionsWindowController = controller
        let oldField = NSTextField()
        delegate.targetTextField = oldField

        delegate.targetTextField = nil

        XCTAssertNil(oldField.delegate)
        XCTAssertNil(oldField.target)
        XCTAssertNil(oldField.action)
        XCTAssertNil(controller.parentTextField)
    }

    func testReplacementPreservesExternallyChangedDelegate() {
        let delegate = SuggestionsTextFieldDelegate()
        let oldField = NSTextField()
        delegate.targetTextField = oldField
        let externalDelegate = ExternalTextFieldDelegate()
        oldField.delegate = externalDelegate

        delegate.targetTextField = NSTextField()

        XCTAssertTrue(oldField.delegate === externalDelegate)
        XCTAssertNil(oldField.target)
        XCTAssertNil(oldField.action)
    }

    func testReplacementPreservesExternallyChangedTargetAndItsAction() {
        let delegate = SuggestionsTextFieldDelegate()
        let oldField = NSTextField()
        delegate.targetTextField = oldField
        let externalTarget = NSObject()
        oldField.target = externalTarget
        let action = oldField.action

        delegate.targetTextField = NSTextField()

        XCTAssertNil(oldField.delegate)
        XCTAssertTrue(oldField.target === externalTarget)
        XCTAssertEqual(oldField.action, action)
    }

    func testReplacementPreservesExternallyChangedActionAndItsTarget() {
        let delegate = SuggestionsTextFieldDelegate()
        let oldField = NSTextField()
        delegate.targetTextField = oldField
        let action = #selector(NSResponder.insertTab(_:))
        oldField.action = action

        delegate.targetTextField = NSTextField()

        XCTAssertNil(oldField.delegate)
        XCTAssertTrue(oldField.target === delegate)
        XCTAssertEqual(oldField.action, action)
    }

    func testClearingTargetPreservesExternallyReplacedWiring() {
        let delegate = SuggestionsTextFieldDelegate()
        let oldField = NSTextField()
        delegate.targetTextField = oldField
        let externalDelegate = ExternalTextFieldDelegate()
        let externalTarget = NSObject()
        let action = #selector(NSResponder.insertTab(_:))
        oldField.delegate = externalDelegate
        oldField.target = externalTarget
        oldField.action = action

        delegate.targetTextField = nil

        XCTAssertTrue(oldField.delegate === externalDelegate)
        XCTAssertTrue(oldField.target === externalTarget)
        XCTAssertEqual(oldField.action, action)
    }

    func testAssigningSameTargetPreservesExternallyChangedWiring() {
        let delegate = SuggestionsTextFieldDelegate()
        let field = NSTextField()
        delegate.targetTextField = field
        let externalDelegate = ExternalTextFieldDelegate()
        let externalTarget = NSObject()
        let action = #selector(NSResponder.insertTab(_:))
        field.delegate = externalDelegate
        field.target = externalTarget
        field.action = action

        delegate.targetTextField = field

        XCTAssertTrue(field.delegate === externalDelegate)
        XCTAssertTrue(field.target === externalTarget)
        XCTAssertEqual(field.action, action)
    }

    func testAssigningSameTargetKeepsVisiblePopupAndObservers() throws {
        let window = makeWindow()
        let field = addTextField(to: window)
        let (delegate, controller) = makeDelegate(for: field)
        defer {
            controller.cancelSuggestions()
            window.orderOut(nil)
        }
        controller.enableSuggestions()
        let popup = try XCTUnwrap(controller.window)
        let cancelCount = controller.cancelCount

        delegate.targetTextField = field

        XCTAssertEqual(controller.cancelCount, cancelCount)
        XCTAssertTrue(popup.isVisible)
        XCTAssertTrue(popup.parent === window)
        XCTAssertTrue(field.delegate === delegate)
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: window)
        XCTAssertEqual(controller.cancelCount, cancelCount + 1)
        XCTAssertFalse(popup.isVisible)
    }

    func testClearingTargetCancelsVisiblePopupAndRemovesObservers() throws {
        let window = makeWindow()
        let field = addTextField(to: window)
        let (delegate, controller) = makeDelegate(for: field)
        defer {
            controller.cancelSuggestions()
            window.orderOut(nil)
        }
        controller.enableSuggestions()
        let popup = try XCTUnwrap(controller.window as? SuggestionsWindow)
        XCTAssertTrue(popup.isVisible)
        let cancelCount = controller.cancelCount

        delegate.targetTextField = nil

        XCTAssertEqual(controller.cancelCount, cancelCount + 1)
        XCTAssertFalse(popup.isVisible)
        XCTAssertNil(popup.parent)
        XCTAssertNil(popup.parentElement)
        XCTAssertNil(controller.parentTextField)
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: window)
        sendMouseDown(in: nil, at: .zero)
        XCTAssertEqual(controller.cancelCount, cancelCount + 1)
    }

    func testClearingTargetDisconnectsHiddenPopupAccessibilityParentAndRemovesObservers() throws {
        let window = makeWindow()
        let field = addTextField(to: window)
        let (delegate, controller) = makeDelegate(for: field)
        defer {
            controller.cancelSuggestions()
            window.orderOut(nil)
        }
        controller.enableSuggestions()
        let popup = try XCTUnwrap(controller.window as? SuggestionsWindow)
        XCTAssertTrue(popup.isVisible)

        popup.orderOut(nil)

        XCTAssertFalse(popup.isVisible)
        XCTAssertNotNil(popup.parentElement)
        let cancelCount = controller.cancelCount

        delegate.targetTextField = nil

        XCTAssertEqual(controller.cancelCount, cancelCount + 1)
        XCTAssertFalse(popup.isVisible)
        XCTAssertNil(popup.parent)
        XCTAssertNil(popup.parentElement)
        XCTAssertFalse(window.childWindows?.contains { $0 === popup } == true)
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: window)
        sendMouseDown(in: nil, at: .zero)
        XCTAssertEqual(controller.cancelCount, cancelCount + 1)
    }

    func testReplacingVisibleTargetAcrossWindowsMovesPopupAndRebuildsObserversOnNewInput() throws {
        let oldWindow = makeWindow()
        let newWindow = makeWindow()
        let oldField = addTextField(to: oldWindow)
        let newField = addTextField(to: newWindow)
        let (delegate, controller) = makeDelegate(for: oldField)
        defer {
            controller.cancelSuggestions()
            oldWindow.orderOut(nil)
            newWindow.orderOut(nil)
        }
        controller.enableSuggestions()
        let popup = try XCTUnwrap(controller.window as? SuggestionsWindow)
        XCTAssertTrue(popup.isVisible)
        XCTAssertTrue(popup.parent === oldWindow)
        let cancelCount = controller.cancelCount

        delegate.targetTextField = newField

        XCTAssertEqual(controller.cancelCount, cancelCount + 1)
        XCTAssertFalse(popup.isVisible)
        XCTAssertNil(popup.parent)
        XCTAssertNil(popup.parentElement)
        XCTAssertFalse(oldWindow.childWindows?.contains { $0 === popup } == true)
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: oldWindow)
        XCTAssertEqual(controller.cancelCount, cancelCount + 1)

        let editor = NSTextView()
        editor.string = "New window input"
        newField.editor = editor
        delegate.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification, object: newField))

        XCTAssertEqual(delegate.suggestionsDataSource?.inputString, "New window input")
        XCTAssertTrue(popup.isVisible)
        XCTAssertTrue(popup.parent === newWindow)
        XCTAssertNotNil(popup.parentElement)
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: oldWindow)
        sendMouseDown(in: newWindow, at: NSPoint(x: newField.frame.midX, y: newField.frame.midY))
        XCTAssertEqual(controller.cancelCount, cancelCount + 1)
        XCTAssertTrue(popup.isVisible)
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: newWindow)
        XCTAssertEqual(controller.cancelCount, cancelCount + 2)
        XCTAssertFalse(popup.isVisible)
        XCTAssertNil(popup.parent)
    }

    private func makeWindow() -> NSWindow {
        let window = TargetReplacementWindow(
            contentRect: NSRect(x: 100, y: 200, width: 400, height: 200),
            styleMask: .titled, backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.orderFront(nil)
        return window
    }

    private func addTextField(to window: NSWindow) -> TargetReplacementTextField {
        let field = TargetReplacementTextField(frame: NSRect(x: 20, y: 80, width: 260, height: 24))
        window.contentView?.addSubview(field)
        return field
    }

    private func makeDelegate(
        for field: NSTextField
    ) -> (SuggestionsTextFieldDelegate, TargetReplacementController) {
        let delegate = SuggestionsTextFieldDelegate()
        let controller = TargetReplacementController()
        controller.window?.setFrame(NSRect(x: 0, y: 0, width: 270, height: 100), display: false)
        let dataSource = MockSuggestionsDataSource()
        dataSource.suggestions = [Suggestion(imageName: "", displayText: "Suggestion", data: 1)]
        delegate.suggestionsDataSource = dataSource
        delegate.suggestionsWindowController = controller
        delegate.targetTextField = field
        return (delegate, controller)
    }

    private func sendMouseDown(in window: NSWindow?, at point: NSPoint) {
        let event = TargetReplacementMouseEvent()
        event.targetWindow = window
        event.point = point
        NSApplication.shared.sendEvent(event)
    }
}

private final class ExternalTextFieldDelegate: NSObject, NSTextFieldDelegate {}

private final class TargetReplacementController: SuggestionsWindowController {
    private(set) var cancelCount = 0
    override func cancelSuggestions() {
        cancelCount += 1
        super.cancelSuggestions()
    }
}

private final class TargetReplacementTextField: NSTextField {
    var editor: NSText?
    override func currentEditor() -> NSText? { editor }
}

private final class TargetReplacementMouseEvent: NSEvent {
    var targetWindow: NSWindow?
    var point: NSPoint = .zero
    override var window: NSWindow? { targetWindow }
    override var locationInWindow: NSPoint { point }
    override var type: NSEvent.EventType { .leftMouseDown }
}

// Application event monitors run normally, then window dispatch avoids interactive tracking.
private final class TargetReplacementWindow: NSWindow {
    override func sendEvent(_ event: NSEvent) {}
}
