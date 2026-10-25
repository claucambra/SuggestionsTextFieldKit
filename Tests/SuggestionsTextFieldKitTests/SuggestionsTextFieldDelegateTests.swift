import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

class SuggestionsTextFieldDelegateTests: XCTestCase {
    func testBeginningEditingUsesNonemptyEditorString() {
        let (delegate, dataSource, controller, textField) = makeDelegate(
            committedString: "", editorString: "Uncommitted input"
        )

        delegate.controlTextDidBeginEditing(notification(for: textField))

        XCTAssertEqual(dataSource.inputString, "Uncommitted input")
        XCTAssertEqual(controller.enableCount, 1)
        XCTAssertEqual(controller.cancelCount, 0)
        XCTAssertEqual(textField.stringValueReadCount, 0)
    }

    func testBeginningEditingUsesEmptyEditorString() {
        let (delegate, dataSource, controller, textField) = makeDelegate(
            committedString: "Previous value", editorString: ""
        )
        dataSource.inputString = "Previous input"

        delegate.controlTextDidBeginEditing(notification(for: textField))

        XCTAssertEqual(dataSource.inputString, "")
        XCTAssertEqual(controller.enableCount, 0)
        XCTAssertEqual(controller.cancelCount, 0)
        XCTAssertEqual(textField.stringValueReadCount, 0)
    }

    func testChangingTextUsesNonemptyEditorString() {
        let (delegate, dataSource, controller, textField) = makeDelegate(
            committedString: "", editorString: "Uncommitted input"
        )

        delegate.controlTextDidChange(notification(for: textField))

        XCTAssertEqual(dataSource.inputString, "Uncommitted input")
        XCTAssertEqual(controller.enableCount, 1)
        XCTAssertEqual(controller.cancelCount, 0)
        XCTAssertEqual(textField.stringValueReadCount, 0)
    }

    func testClearingEditorCancelsSuggestions() {
        let (delegate, dataSource, controller, textField) = makeDelegate(
            committedString: "Previous value", editorString: ""
        )
        dataSource.inputString = "Previous input"

        delegate.controlTextDidChange(notification(for: textField))

        XCTAssertEqual(dataSource.inputString, "")
        XCTAssertEqual(controller.enableCount, 0)
        XCTAssertEqual(controller.cancelCount, 1)
        XCTAssertEqual(textField.stringValueReadCount, 0)
    }

    func testBeginningEditingWithoutEditorIsIgnored() {
        let delegate = SuggestionsTextFieldDelegate()
        let dataSource = MockSuggestionsDataSource()
        dataSource.inputString = "Previous input"
        delegate.suggestionsDataSource = dataSource
        let textField = EditorTextField()
        textField.hasEditor = false

        delegate.controlTextDidBeginEditing(notification(for: textField))

        XCTAssertEqual(dataSource.inputString, "Previous input")
        XCTAssertNil(delegate.suggestionsWindowController)
        XCTAssertEqual(textField.stringValueReadCount, 0)
    }

    func testChangingTextWithoutEditorIsIgnored() {
        let delegate = SuggestionsTextFieldDelegate()
        let dataSource = MockSuggestionsDataSource()
        dataSource.inputString = "Previous input"
        delegate.suggestionsDataSource = dataSource
        let textField = EditorTextField()
        textField.hasEditor = false

        delegate.controlTextDidChange(notification(for: textField))

        XCTAssertEqual(dataSource.inputString, "Previous input")
        XCTAssertNil(delegate.suggestionsWindowController)
        XCTAssertEqual(textField.stringValueReadCount, 0)
    }

    func testEditingCallbacksDoNotCommitFieldEditor() throws {
        _ = NSApplication.shared
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
            styleMask: .titled, backing: .buffered, defer: false
        )
        let textField = NSTextField(frame: NSRect(x: 20, y: 20, width: 260, height: 24))
        textField.stringValue = "Previous value"
        window.contentView?.addSubview(textField)
        XCTAssertTrue(window.makeFirstResponder(textField))
        let editor = try XCTUnwrap(textField.currentEditor())
        defer { window.orderOut(nil) }

        let delegate = SuggestionsTextFieldDelegate()
        let dataSource = MockSuggestionsDataSource()
        delegate.suggestionsDataSource = dataSource
        delegate.targetTextField = textField
        defer { delegate.suggestionsWindowController?.cancelSuggestions() }
        editor.string = "Uncommitted input"

        delegate.controlTextDidBeginEditing(notification(for: textField))
        XCTAssertEqual(dataSource.inputString, "Uncommitted input")
        delegate.suggestionsWindowController?.cancelSuggestions()

        editor.string = "Changed input"
        delegate.controlTextDidChange(notification(for: textField))
        XCTAssertEqual(dataSource.inputString, "Changed input")

        XCTAssertTrue(textField.abortEditing())
        XCTAssertEqual(textField.stringValue, "Previous value")
    }

    private func makeDelegate(
        committedString: String, editorString: String
    ) -> (
        SuggestionsTextFieldDelegate, MockSuggestionsDataSource,
        TrackingSuggestionsWindowController, EditorTextField
    ) {
        let delegate = SuggestionsTextFieldDelegate()
        let dataSource = MockSuggestionsDataSource()
        let controller = TrackingSuggestionsWindowController()
        let textField = EditorTextField()
        textField.stringValue = committedString
        textField.editor.string = editorString
        delegate.suggestionsDataSource = dataSource
        delegate.suggestionsWindowController = controller
        return (delegate, dataSource, controller, textField)
    }

    private func notification(for textField: NSTextField) -> Notification {
        Notification(name: NSControl.textDidChangeNotification, object: textField)
    }
}

private class EditorTextField: NSTextField {
    let editor = NSTextView()
    var hasEditor = true
    var stringValueReadCount = 0

    override var stringValue: String {
        get {
            stringValueReadCount += 1
            return super.stringValue
        }
        set { super.stringValue = newValue }
    }

    override func currentEditor() -> NSText? {
        hasEditor ? editor : nil
    }
}

private class TrackingSuggestionsWindowController: SuggestionsWindowController {
    var enableCount = 0
    var cancelCount = 0

    override func enableSuggestions() {
        enableCount += 1
    }

    override func cancelSuggestions() {
        cancelCount += 1
    }
}
