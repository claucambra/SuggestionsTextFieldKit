import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionsMouseDismissalTests: XCTestCase {
    private var controller: MouseDismissalController!
    private var parentWindow: MouseDismissalWindow!
    private var textField: MouseDismissalTextField!

    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
        parentWindow = MouseDismissalWindow(
            contentRect: NSRect(x: 100, y: 200, width: 480, height: 240),
            styleMask: .titled, backing: .buffered, defer: false
        )
        parentWindow.isReleasedWhenClosed = false
        textField = MouseDismissalTextField(frame: NSRect(x: 30, y: 120, width: 260, height: 24))
        parentWindow.contentView?.addSubview(textField)
        parentWindow.orderFront(nil)
        // Ordering the window can start editing its first text field automatically.
        // End that edit so tests without an editor also have no editor overlay to hit.
        parentWindow.makeFirstResponder(nil)

        controller = MouseDismissalController()
        let popup = MouseDismissalPopupWindow(
            contentRect: NSRect(x: 0, y: 0, width: 270, height: 100), defer: true
        )
        popup.contentView = controller.window?.contentView
        popup.isReleasedWhenClosed = false
        controller.window = popup
        controller.parentTextField = textField
        let dataSource = MockSuggestionsDataSource()
        dataSource.suggestions = [Suggestion(imageName: "", displayText: "Suggestion", data: 1)]
        controller.dataSource = dataSource
        controller.enableSuggestions()
    }

    override func tearDown() {
        controller.cancelSuggestions()
        parentWindow.orderOut(nil)
        controller = nil
        textField = nil
        parentWindow = nil
        super.tearDown()
    }

    func testClickingPopupKeepsSuggestionsVisible() throws {
        let popup = try XCTUnwrap(controller.window)

        sendMouseDown(in: popup, at: NSPoint(x: popup.frame.width / 2, y: popup.frame.height / 2))

        XCTAssertEqual(controller.cancelCount, 0)
        XCTAssertTrue(popup.isVisible)
        XCTAssertTrue(popup.parent === parentWindow)
    }

    func testClickingTextFieldWithoutEditorKeepsSuggestionsVisible() throws {
        XCTAssertNil(textField.currentEditor())
        let point = NSPoint(x: textField.frame.midX, y: textField.frame.midY)
        XCTAssertTrue(parentWindow.contentView?.hitTest(point) === textField)

        sendMouseDown(in: parentWindow, at: point)

        XCTAssertEqual(controller.cancelCount, 0)
        XCTAssertTrue(try XCTUnwrap(controller.window).isVisible)
    }

    func testClickingFieldEditorKeepsSuggestionsVisible() throws {
        let editor = addFieldEditor()
        let point = NSPoint(x: editor.frame.midX, y: editor.frame.midY)
        XCTAssertTrue(parentWindow.contentView?.hitTest(point) === editor)

        sendMouseDown(in: parentWindow, at: point)

        XCTAssertEqual(controller.cancelCount, 0)
        XCTAssertTrue(try XCTUnwrap(controller.window).isVisible)
    }

    func testClickingOutsideTextFieldWhileEditingDismissesSuggestions() throws {
        _ = addFieldEditor()

        sendMouseDown(in: parentWindow, at: NSPoint(x: 400, y: 40))

        XCTAssertEqual(controller.cancelCount, 1)
        try assertPopupDismissed()
    }

    func testAllMouseButtonsOutsideTextFieldWithoutEditorDismissSuggestions() throws {
        XCTAssertNil(textField.currentEditor())

        for (index, type) in [NSEvent.EventType.leftMouseDown, .rightMouseDown, .otherMouseDown].enumerated() {
            if index > 0 { controller.enableSuggestions() }
            sendMouseDown(in: parentWindow, at: NSPoint(x: 400, y: 40), type: type)

            XCTAssertEqual(controller.cancelCount, index + 1, "Mouse event: \(type)")
            try assertPopupDismissed()
        }
    }

    func testClickingAnotherWindowDismissesSuggestions() throws {
        let otherWindow = MouseDismissalWindow(
            contentRect: NSRect(x: 600, y: 200, width: 200, height: 100),
            styleMask: .borderless, backing: .buffered, defer: true
        )
        otherWindow.isReleasedWhenClosed = false

        sendMouseDown(in: otherWindow, at: NSPoint(x: 20, y: 20))

        XCTAssertEqual(controller.cancelCount, 1)
        try assertPopupDismissed()
    }

    func testMouseEventWithoutWindowDismissesSuggestions() throws {
        sendMouseDown(in: nil, at: .zero)

        XCTAssertEqual(controller.cancelCount, 1)
        try assertPopupDismissed()
    }

    func testMissingParentContentViewDismissesSuggestions() throws {
        parentWindow.contentView = nil

        sendMouseDown(in: parentWindow, at: .zero)

        XCTAssertEqual(controller.cancelCount, 1)
        try assertPopupDismissed()
    }

    func testCancellationRemovesMouseMonitor() throws {
        controller.cancelSuggestions()
        let cancelCount = controller.cancelCount

        sendMouseDown(in: nil, at: .zero)

        XCTAssertEqual(controller.cancelCount, cancelCount)
        try assertPopupDismissed()
    }

    private func addFieldEditor() -> NSTextView {
        let editor = NSTextView(frame: textField.frame)
        parentWindow.contentView?.addSubview(editor)
        textField.editor = editor
        return editor
    }

    private func sendMouseDown(
        in window: NSWindow?, at point: NSPoint,
        type: NSEvent.EventType = .leftMouseDown
    ) {
        let event = MouseDismissalEvent()
        event.targetWindow = window
        event.point = point
        event.eventType = type
        // Send through NSApplication so the installed local monitor handles the event.
        NSApplication.shared.sendEvent(event)
    }

    private func assertPopupDismissed(file: StaticString = #filePath, line: UInt = #line) throws {
        let popup = try XCTUnwrap(controller.window as? SuggestionsWindow, file: file, line: line)
        XCTAssertFalse(popup.isVisible, file: file, line: line)
        XCTAssertNil(popup.parent, file: file, line: line)
        XCTAssertNil(popup.parentElement, file: file, line: line)
    }
}

private final class MouseDismissalController: SuggestionsWindowController {
    private(set) var cancelCount = 0

    override func cancelSuggestions() {
        cancelCount += 1
        super.cancelSuggestions()
    }
}

private final class MouseDismissalTextField: NSTextField {
    var editor: NSText?
    override func currentEditor() -> NSText? { editor }
}

private final class MouseDismissalEvent: NSEvent {
    var targetWindow: NSWindow?
    var point: NSPoint = .zero
    var eventType: NSEvent.EventType = .leftMouseDown

    override var window: NSWindow? { targetWindow }
    override var locationInWindow: NSPoint { point }
    override var type: NSEvent.EventType { eventType }
}

// The monitor receives real application event dispatch, while the destination windows
// avoid starting AppKit's interactive mouse tracking loop after the monitor returns.
private final class MouseDismissalWindow: NSWindow {
    override func sendEvent(_ event: NSEvent) {}
}

private final class MouseDismissalPopupWindow: SuggestionsWindow {
    override func sendEvent(_ event: NSEvent) {}
}
