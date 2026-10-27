import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionsConfirmationIntegrationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    func testMouseSelectionConfirmsOnceThroughRealDelegateTargetAction() throws {
        let fixture = ConfirmationIntegrationFixture()
        fixture.selectSecondSuggestion()

        fixture.controller.mouseUp(with: try confirmationMouseUpEvent())

        XCTAssertEqual(fixture.confirmations.values, [20])
    }

    func testMouseUpWithoutSelectionConfirmsNilOnceThroughRealDelegateTargetAction() throws {
        let fixture = ConfirmationIntegrationFixture()

        fixture.controller.mouseUp(with: try confirmationMouseUpEvent())

        XCTAssertEqual(fixture.confirmations.values, [nil])
    }

    func testKeyboardTargetActionStillConfirmsSelectedAndNilSuggestions() {
        let fixture = ConfirmationIntegrationFixture()
        fixture.selectSecondSuggestion()

        XCTAssertTrue(fixture.textField.sendAction(fixture.textField.action, to: fixture.textField.target))
        fixture.controller.moveUp(nil)
        fixture.controller.moveUp(nil)
        XCTAssertTrue(fixture.textField.sendAction(fixture.textField.action, to: fixture.textField.target))

        XCTAssertEqual(fixture.confirmations.values, [20, nil])
    }

    func testKeyboardTargetActionWorksAfterMouseConfirmationCompletes() throws {
        let fixture = ConfirmationIntegrationFixture()
        fixture.selectSecondSuggestion()
        fixture.controller.mouseUp(with: try confirmationMouseUpEvent())

        XCTAssertTrue(fixture.textField.sendAction(fixture.textField.action, to: fixture.textField.target))

        XCTAssertEqual(fixture.confirmations.values, [20, 20])
    }

    func testStandaloneControllerDeliversExternalActionAndConfirmsOnce() throws {
        let controller = makeConfirmationController()
        defer { controller.cancelSuggestions() }
        let textField = NSTextField()
        let target = ConfirmationIntegrationActionTarget()
        let confirmations = ConfirmationIntegrationRecorder()
        textField.target = target
        textField.action = #selector(ConfirmationIntegrationActionTarget.accept(_:))
        controller.parentTextField = textField
        controller.confirmationHandler = { confirmations.record($0) }
        controller.moveDown(nil)

        controller.mouseUp(with: try confirmationMouseUpEvent())

        XCTAssertEqual(target.actionCount, 1)
        XCTAssertTrue(target.lastSender === textField)
        XCTAssertEqual(confirmations.values, [10])
    }

    func testFailedTargetActionStillConfirmsMouseSelectionOnce() throws {
        let textField = RejectingConfirmationTextField()
        let fixture = ConfirmationIntegrationFixture(textField: textField)
        fixture.selectSecondSuggestion()

        fixture.controller.mouseUp(with: try confirmationMouseUpEvent())

        XCTAssertEqual(textField.actionAttemptCount, 1)
        XCTAssertEqual(fixture.confirmations.values, [20])
    }

    func testMissingActionTargetStillConfirmsMouseSelectionOnce() throws {
        let fixture = ConfirmationIntegrationFixture()
        fixture.selectSecondSuggestion()
        fixture.textField.target = nil
        fixture.textField.action = #selector(ConfirmationIntegrationActionTarget.accept(_:))

        fixture.controller.mouseUp(with: try confirmationMouseUpEvent())

        XCTAssertEqual(fixture.confirmations.values, [20])
    }

    func testExternalActionChangingSelectionDoesNotChangeConfirmedPayload() throws {
        let controller = makeConfirmationController()
        defer { controller.cancelSuggestions() }
        let textField = NSTextField()
        let target = ConfirmationIntegrationActionTarget()
        let confirmations = ConfirmationIntegrationRecorder()
        textField.target = target
        textField.action = #selector(ConfirmationIntegrationActionTarget.accept(_:))
        controller.parentTextField = textField
        controller.confirmationHandler = { confirmations.record($0) }
        controller.moveDown(nil)
        target.onAction = { controller.moveDown(nil) }

        controller.mouseUp(with: try confirmationMouseUpEvent())

        XCTAssertEqual(target.actionCount, 1)
        XCTAssertEqual(controller.selectedSuggestion?.data as? Int, 20)
        XCTAssertEqual(confirmations.values, [10])
    }

    func testValidationCanReenterDelegateAndChangeSelectionWithoutChangingMouseAcceptance() throws {
        let textField = ValidatingConfirmationTextField()
        let fixture = ConfirmationIntegrationFixture(textField: textField)
        fixture.selectSecondSuggestion()
        textField.onValidate = {
            fixture.delegate.acceptSuggestion(sender: textField)
            fixture.controller.moveUp(nil)
        }
        defer { textField.onValidate = nil }

        fixture.controller.mouseUp(with: try confirmationMouseUpEvent())

        XCTAssertEqual(fixture.controller.selectedSuggestion?.data as? Int, 10)
        XCTAssertEqual(fixture.confirmations.values, [20])
    }

    func testValidationReplacingDelegateControllerStillConfirmsOriginalMousePayloadOnce() throws {
        let textField = ValidatingConfirmationTextField()
        let fixture = ConfirmationIntegrationFixture(textField: textField)
        fixture.selectSecondSuggestion()
        let replacement = makeConfirmationController()
        textField.onValidate = {
            fixture.delegate.suggestionsWindowController = replacement
            replacement.moveDown(nil)
        }
        defer {
            textField.onValidate = nil
            replacement.cancelSuggestions()
        }

        fixture.controller.mouseUp(with: try confirmationMouseUpEvent())

        XCTAssertTrue(fixture.delegate.suggestionsWindowController === replacement)
        XCTAssertEqual(fixture.confirmations.values, [20])
        XCTAssertTrue(fixture.textField.sendAction(fixture.textField.action, to: fixture.textField.target))
        XCTAssertEqual(fixture.confirmations.values, [20, 10])
    }

    func testExternalActionRelayoutDoesNotDiscardConfirmedPayload() throws {
        let controller = makeConfirmationController()
        defer { controller.cancelSuggestions() }
        let textField = NSTextField()
        let target = ConfirmationIntegrationActionTarget()
        let confirmations = ConfirmationIntegrationRecorder()
        textField.target = target
        textField.action = #selector(ConfirmationIntegrationActionTarget.accept(_:))
        controller.parentTextField = textField
        controller.confirmationHandler = { confirmations.record($0) }
        controller.moveDown(nil)
        let dataSource = try XCTUnwrap(controller.dataSource as? MockSuggestionsDataSource)
        target.onAction = {
            dataSource.suggestions = [Suggestion(imageName: "", displayText: "Replacement", data: 99)]
            NotificationCenter.default.post(name: SuggestionsChangedNotificationName, object: dataSource)
        }

        controller.mouseUp(with: try confirmationMouseUpEvent())

        XCTAssertEqual(target.actionCount, 1)
        XCTAssertNil(controller.selectedSuggestion)
        XCTAssertEqual(confirmations.values, [10])
    }

    func testReentrantMouseUpFromExternalActionIsIgnored() throws {
        let controller = makeConfirmationController()
        defer { controller.cancelSuggestions() }
        let textField = NSTextField()
        let target = ConfirmationIntegrationActionTarget()
        let confirmations = ConfirmationIntegrationRecorder()
        let event = try confirmationMouseUpEvent()
        textField.target = target
        textField.action = #selector(ConfirmationIntegrationActionTarget.accept(_:))
        controller.parentTextField = textField
        controller.confirmationHandler = { confirmations.record($0) }
        controller.moveDown(nil)
        var attemptedReentry = false
        target.onAction = {
            guard !attemptedReentry else { return }
            attemptedReentry = true
            controller.mouseUp(with: event)
        }

        controller.mouseUp(with: event)

        XCTAssertTrue(attemptedReentry)
        XCTAssertEqual(target.actionCount, 1)
        XCTAssertEqual(confirmations.values, [10])
    }

    func testReentrantConfirmationCannotDuplicateMouseAcceptanceAndKeyboardStillWorks() throws {
        let fixture = ConfirmationIntegrationFixture()
        fixture.selectSecondSuggestion()
        let event = try confirmationMouseUpEvent()
        fixture.mouseUpEventForReentry = event
        fixture.delegate.confirmationHandler = { suggestion in
            fixture.confirmations.record(suggestion)
            guard fixture.confirmations.values.count == 1 else { return }
            fixture.reenterAcceptance()
        }
        defer { fixture.delegate.confirmationHandler = nil }

        fixture.controller.mouseUp(with: event)

        XCTAssertEqual(fixture.confirmations.values, [20])
        XCTAssertTrue(fixture.textField.sendAction(fixture.textField.action, to: fixture.textField.target))
        XCTAssertEqual(fixture.confirmations.values, [20, 20])
    }

    func testConfirmationHandlerCanReplaceResultsWithoutAnotherConfirmation() throws {
        let fixture = ConfirmationIntegrationFixture()
        fixture.selectSecondSuggestion()
        fixture.delegate.confirmationHandler = { suggestion in
            fixture.confirmations.record(suggestion)
            fixture.dataSource.suggestions = [Suggestion(imageName: "", displayText: "Replacement", data: 99)]
            NotificationCenter.default.post(name: SuggestionsChangedNotificationName, object: fixture.dataSource)
        }
        defer { fixture.delegate.confirmationHandler = nil }

        fixture.controller.mouseUp(with: try confirmationMouseUpEvent())

        XCTAssertNil(fixture.controller.selectedSuggestion)
        XCTAssertEqual(fixture.confirmations.values, [20])
    }
}

private func makeConfirmationController() -> SuggestionsWindowController {
    let controller = SuggestionsWindowController()
    controller.window?.setFrame(NSRect(x: 0, y: 0, width: 240, height: 100), display: false)
    let dataSource = MockSuggestionsDataSource()
    dataSource.suggestions = [
        Suggestion(imageName: "", displayText: "Result", data: 10),
        Suggestion(imageName: "", displayText: "Result", data: 20),
    ]
    controller.dataSource = dataSource
    return controller
}

private func confirmationMouseUpEvent() throws -> NSEvent {
    try XCTUnwrap(NSEvent.mouseEvent(
        with: .leftMouseUp, location: .zero, modifierFlags: [], timestamp: 0,
        windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 0
    ))
}

// AppKit objects are used synchronously by the test's action and confirmation callbacks.
private final class ConfirmationIntegrationFixture: @unchecked Sendable {
    let delegate = SuggestionsTextFieldDelegate()
    let controller = makeConfirmationController()
    let textField: NSTextField
    let dataSource: MockSuggestionsDataSource
    let confirmations = ConfirmationIntegrationRecorder()
    var mouseUpEventForReentry: NSEvent?

    init(textField: NSTextField = NSTextField()) {
        self.textField = textField
        self.dataSource = controller.dataSource as! MockSuggestionsDataSource
        delegate.targetTextField = textField
        delegate.suggestionsDataSource = dataSource
        delegate.confirmationHandler = { [confirmations] in confirmations.record($0) }
        delegate.suggestionsWindowController = controller
    }

    deinit {
        controller.cancelSuggestions()
    }

    func selectSecondSuggestion() {
        controller.moveDown(nil)
        controller.moveDown(nil)
    }

    func reenterAcceptance() {
        guard let event = mouseUpEventForReentry else {
            XCTFail("The synchronous reentry callback requires a mouse event")
            return
        }
        delegate.acceptSuggestion(sender: textField)
        controller.mouseUp(with: event)
    }
}

private final class ConfirmationIntegrationRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValues: [Int?] = []

    var values: [Int?] {
        lock.lock()
        defer { lock.unlock() }
        return storedValues
    }

    func record(_ suggestion: Suggestion?) {
        lock.lock()
        defer { lock.unlock() }
        storedValues.append(suggestion?.data as? Int)
    }
}

private final class ConfirmationIntegrationActionTarget: NSObject {
    var actionCount = 0
    weak var lastSender: NSControl?
    var onAction: (() -> Void)?

    @objc func accept(_ sender: Any) {
        actionCount += 1
        lastSender = sender as? NSControl
        onAction?()
    }
}

private final class RejectingConfirmationTextField: NSTextField {
    var actionAttemptCount = 0

    override func sendAction(_ action: Selector?, to target: Any?) -> Bool {
        actionAttemptCount += 1
        return false
    }
}

private final class ValidatingConfirmationTextField: NSTextField {
    var onValidate: (() -> Void)?

    override func validateEditing() {
        super.validateEditing()
        onValidate?()
    }
}
