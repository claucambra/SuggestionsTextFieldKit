import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

class SuggestionsTextFieldDelegateInteractionTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    func testAttachingControllerPropagatesExistingConfiguration() {
        let delegate = SuggestionsTextFieldDelegate()
        let textField = NSTextField()
        let dataSource = MockSuggestionsDataSource()
        let selections = DelegateCallbackRecorder()
        let confirmations = DelegateCallbackRecorder()
        delegate.targetTextField = textField
        delegate.suggestionsDataSource = dataSource
        delegate.selectionHandler = { selections.record($0) }
        delegate.confirmationHandler = { confirmations.record($0) }

        let controller = DelegateInteractionWindowController()
        delegate.suggestionsWindowController = controller
        controller.selectionHandler?(nil)
        controller.confirmationHandler?(nil)

        XCTAssertTrue(controller.parentTextField === textField)
        XCTAssertTrue(controller.dataSource as? MockSuggestionsDataSource === dataSource)
        XCTAssertTrue(textField.delegate === delegate)
        XCTAssertTrue(textField.target === delegate)
        XCTAssertEqual(textField.action, #selector(SuggestionsTextFieldDelegate.acceptSuggestion(sender:)))
        XCTAssertEqual(selections.values.count, 1)
        XCTAssertEqual(confirmations.values.count, 1)
    }

    func testReplacingControllerReceivesCurrentConfiguration() {
        let delegate = SuggestionsTextFieldDelegate()
        let firstController = DelegateInteractionWindowController()
        delegate.suggestionsWindowController = firstController
        let textField = NSTextField()
        let dataSource = MockSuggestionsDataSource()
        let confirmations = DelegateCallbackRecorder()
        delegate.targetTextField = textField
        delegate.suggestionsDataSource = dataSource
        delegate.confirmationHandler = { confirmations.record($0) }

        let replacement = DelegateInteractionWindowController()
        delegate.suggestionsWindowController = replacement
        replacement.confirmationHandler?(nil)

        XCTAssertTrue(replacement.parentTextField === textField)
        XCTAssertTrue(replacement.dataSource as? MockSuggestionsDataSource === dataSource)
        XCTAssertEqual(confirmations.values.count, 1)
    }

    func testReplacingTextFieldAndDataSourceUpdatesAttachedController() {
        let delegate = SuggestionsTextFieldDelegate()
        let controller = DelegateInteractionWindowController()
        delegate.suggestionsWindowController = controller
        delegate.targetTextField = NSTextField()
        delegate.suggestionsDataSource = MockSuggestionsDataSource()

        let replacementField = NSTextField()
        let replacementSource = MockSuggestionsDataSource()
        delegate.targetTextField = replacementField
        delegate.suggestionsDataSource = replacementSource

        XCTAssertTrue(controller.parentTextField === replacementField)
        XCTAssertTrue(controller.dataSource as? MockSuggestionsDataSource === replacementSource)
        XCTAssertTrue(replacementField.delegate === delegate)
        XCTAssertTrue(replacementField.target === delegate)
        XCTAssertEqual(replacementField.action, #selector(SuggestionsTextFieldDelegate.acceptSuggestion(sender:)))
    }

    func testReplacingHandlersUpdatesAttachedController() {
        let delegate = SuggestionsTextFieldDelegate()
        let controller = DelegateInteractionWindowController()
        delegate.suggestionsWindowController = controller
        let original = DelegateCallbackRecorder()
        delegate.selectionHandler = { original.record($0) }
        delegate.confirmationHandler = { original.record($0) }
        let selections = DelegateCallbackRecorder()
        let confirmations = DelegateCallbackRecorder()

        delegate.selectionHandler = { selections.record($0) }
        delegate.confirmationHandler = { confirmations.record($0) }
        controller.selectionHandler?(nil)
        controller.confirmationHandler?(nil)

        XCTAssertTrue(original.values.isEmpty)
        XCTAssertEqual(selections.values.count, 1)
        XCTAssertEqual(confirmations.values.count, 1)
    }

    func testClearingConfigurationClearsAttachedControllerReferences() {
        let delegate = SuggestionsTextFieldDelegate()
        let controller = DelegateInteractionWindowController()
        delegate.suggestionsWindowController = controller
        delegate.targetTextField = NSTextField()
        delegate.suggestionsDataSource = MockSuggestionsDataSource()
        delegate.selectionHandler = { _ in }
        delegate.confirmationHandler = { _ in }

        delegate.targetTextField = nil
        delegate.suggestionsDataSource = nil
        delegate.selectionHandler = nil
        delegate.confirmationHandler = nil

        XCTAssertNil(controller.parentTextField)
        XCTAssertNil(controller.dataSource)
        XCTAssertNil(controller.selectionHandler)
        XCTAssertNil(controller.confirmationHandler)
    }

    func testArrowCommandsForwardFieldEditorToController() {
        let delegate = SuggestionsTextFieldDelegate()
        let controller = DelegateInteractionWindowController()
        delegate.suggestionsWindowController = controller
        let field = NSTextField()
        let editor = NSTextView()

        XCTAssertTrue(delegate.control(field, textView: editor, doCommandBy: #selector(NSResponder.moveUp(_:))))
        XCTAssertTrue(delegate.control(field, textView: editor, doCommandBy: #selector(NSResponder.moveDown(_:))))

        XCTAssertEqual(controller.moveUpCount, 1)
        XCTAssertEqual(controller.moveDownCount, 1)
        XCTAssertTrue(controller.moveUpSender === editor)
        XCTAssertTrue(controller.moveDownSender === editor)
        XCTAssertEqual(controller.enableCount, 0)
        XCTAssertEqual(controller.cancelCount, 0)
    }

    func testCompletionCommandEnablesHiddenSuggestions() {
        let delegate = SuggestionsTextFieldDelegate()
        let controller = DelegateInteractionWindowController()
        delegate.suggestionsWindowController = controller

        XCTAssertTrue(delegate.control(
            NSTextField(), textView: NSTextView(), doCommandBy: #selector(NSResponder.complete(_:))
        ))

        XCTAssertEqual(controller.enableCount, 1)
        XCTAssertEqual(controller.cancelCount, 0)
    }

    func testCompletionCommandCancelsVisibleSuggestions() {
        let delegate = SuggestionsTextFieldDelegate()
        let controller = DelegateInteractionWindowController()
        let window = DelegateVisibilityWindow(
            contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: true
        )
        window.reportsVisible = true
        controller.window = window
        delegate.suggestionsWindowController = controller

        XCTAssertTrue(delegate.control(
            NSTextField(), textView: NSTextView(), doCommandBy: #selector(NSResponder.complete(_:))
        ))

        XCTAssertEqual(controller.enableCount, 0)
        XCTAssertEqual(controller.cancelCount, 1)
    }

    func testUnrecognizedCommandIsLeftToFieldEditor() {
        let delegate = SuggestionsTextFieldDelegate()
        let controller = DelegateInteractionWindowController()
        delegate.suggestionsWindowController = controller

        XCTAssertFalse(delegate.control(
            NSTextField(), textView: NSTextView(), doCommandBy: #selector(NSResponder.insertTab(_:))
        ))

        XCTAssertEqual(controller.moveUpCount, 0)
        XCTAssertEqual(controller.moveDownCount, 0)
        XCTAssertEqual(controller.enableCount, 0)
        XCTAssertEqual(controller.cancelCount, 0)
    }

    func testCommandsWithoutControllerDoNotCreateOne() {
        let delegate = SuggestionsTextFieldDelegate()
        for command in [
            #selector(NSResponder.moveUp(_:)),
            #selector(NSResponder.moveDown(_:)),
            #selector(NSResponder.complete(_:)),
        ] {
            XCTAssertTrue(delegate.control(NSTextField(), textView: NSTextView(), doCommandBy: command))
        }
        XCTAssertNil(delegate.suggestionsWindowController)
    }

    func testEndingEditingCancelsSuggestions() {
        let delegate = SuggestionsTextFieldDelegate()
        let controller = DelegateInteractionWindowController()
        delegate.suggestionsWindowController = controller

        delegate.controlTextDidEndEditing(Notification(name: NSControl.textDidEndEditingNotification))

        XCTAssertEqual(controller.cancelCount, 1)
        XCTAssertEqual(controller.enableCount, 0)
    }

    func testInvalidEditingNotificationsAreIgnored() {
        let delegate = SuggestionsTextFieldDelegate()
        let dataSource = MockSuggestionsDataSource()
        dataSource.inputString = "Previous input"
        delegate.suggestionsDataSource = dataSource

        for object: Any? in [nil, NSObject()] {
            let notification = Notification(name: NSControl.textDidChangeNotification, object: object)
            delegate.controlTextDidBeginEditing(notification)
            delegate.controlTextDidChange(notification)
        }

        XCTAssertEqual(dataSource.inputString, "Previous input")
        XCTAssertNil(delegate.suggestionsWindowController)
    }

    func testBeginningEditingLazilyCreatesConfiguredController() throws {
        let delegate = SuggestionsTextFieldDelegate()
        let textField = DelegateEditorTextField()
        textField.editor.string = "New input"
        let dataSource = MockSuggestionsDataSource()
        let confirmations = DelegateCallbackRecorder()
        delegate.targetTextField = textField
        delegate.suggestionsDataSource = dataSource
        delegate.confirmationHandler = { confirmations.record($0) }

        delegate.controlTextDidBeginEditing(Notification(name: NSControl.textDidBeginEditingNotification, object: textField))
        let controller = try XCTUnwrap(delegate.suggestionsWindowController)
        defer { controller.cancelSuggestions() }
        controller.confirmationHandler?(nil)

        XCTAssertEqual(dataSource.inputString, "New input")
        XCTAssertTrue(controller.parentTextField === textField)
        XCTAssertTrue(controller.dataSource as? MockSuggestionsDataSource === dataSource)
        XCTAssertEqual(confirmations.values.count, 1)
    }

    func testChangingTextLazilyCreatesAndReusesController() throws {
        let delegate = SuggestionsTextFieldDelegate()
        let textField = DelegateEditorTextField()
        let dataSource = MockSuggestionsDataSource()
        delegate.suggestionsDataSource = dataSource
        delegate.targetTextField = textField
        textField.editor.string = "First input"
        let notification = Notification(name: NSControl.textDidChangeNotification, object: textField)

        delegate.controlTextDidChange(notification)
        let controller = try XCTUnwrap(delegate.suggestionsWindowController)
        defer { controller.cancelSuggestions() }
        textField.editor.string = "Changed input"
        delegate.controlTextDidChange(notification)

        XCTAssertTrue(delegate.suggestionsWindowController === controller)
        XCTAssertEqual(dataSource.inputString, "Changed input")
        XCTAssertTrue(controller.parentTextField === textField)
        XCTAssertTrue(controller.dataSource as? MockSuggestionsDataSource === dataSource)
    }

    func testAcceptanceForwardsSelectedSuggestionAndPayload() throws {
        let delegate = SuggestionsTextFieldDelegate()
        let controller = DelegateInteractionWindowController()
        controller.window?.setFrame(NSRect(x: 0, y: 0, width: 240, height: 100), display: false)
        let dataSource = MockSuggestionsDataSource()
        let payload = NSObject()
        dataSource.suggestions = [Suggestion(imageName: "", displayText: "Selected", data: payload)]
        let confirmations = DelegateCallbackRecorder()
        delegate.suggestionsDataSource = dataSource
        delegate.suggestionsWindowController = controller
        delegate.confirmationHandler = { confirmations.record($0) }
        // Use the real navigation implementation to select a row.
        controller.selectFirstSuggestion()

        delegate.acceptSuggestion(sender: NSTextField())

        XCTAssertEqual(confirmations.values.count, 1)
        let confirmed = try XCTUnwrap(confirmations.values.first ?? nil)
        XCTAssertEqual(confirmed.displayText, "Selected")
        XCTAssertTrue(confirmed.data as? NSObject === payload)
    }

    func testAcceptanceWithoutSelectionForwardsNil() {
        let delegate = SuggestionsTextFieldDelegate()
        delegate.suggestionsWindowController = DelegateInteractionWindowController()
        let confirmations = DelegateCallbackRecorder()
        delegate.confirmationHandler = { confirmations.record($0) }

        delegate.acceptSuggestion(sender: NSTextField())

        XCTAssertEqual(confirmations.values.count, 1)
        XCTAssertNil(confirmations.values.first ?? nil)
    }

    func testAcceptanceWithoutControllerDoesNotInvokeConfirmation() {
        let delegate = SuggestionsTextFieldDelegate()
        let confirmations = DelegateCallbackRecorder()
        delegate.confirmationHandler = { confirmations.record($0) }

        delegate.acceptSuggestion(sender: NSTextField())

        XCTAssertTrue(confirmations.values.isEmpty)
        XCTAssertNil(delegate.suggestionsWindowController)
    }
}

private class DelegateInteractionWindowController: SuggestionsWindowController {
    var enableCount = 0
    var cancelCount = 0
    var moveUpCount = 0
    var moveDownCount = 0
    var moveUpSender: AnyObject?
    var moveDownSender: AnyObject?

    override func enableSuggestions() { enableCount += 1 }
    override func cancelSuggestions() { cancelCount += 1 }
    override func moveUp(_ sender: Any?) {
        moveUpCount += 1
        moveUpSender = sender as AnyObject?
    }
    override func moveDown(_ sender: Any?) {
        moveDownCount += 1
        moveDownSender = sender as AnyObject?
    }

    func selectFirstSuggestion() { super.moveDown(nil) }
}

private class DelegateVisibilityWindow: NSWindow {
    var reportsVisible = false
    override var isVisible: Bool { reportsVisible }
}

private class DelegateEditorTextField: NSTextField {
    let editor = NSTextView()
    override func currentEditor() -> NSText? { editor }
}

private final class DelegateCallbackRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedValues: [Suggestion?] = []

    var values: [Suggestion?] {
        lock.lock()
        defer { lock.unlock() }
        return recordedValues
    }

    func record(_ suggestion: Suggestion?) {
        lock.lock()
        defer { lock.unlock() }
        recordedValues.append(suggestion)
    }
}
