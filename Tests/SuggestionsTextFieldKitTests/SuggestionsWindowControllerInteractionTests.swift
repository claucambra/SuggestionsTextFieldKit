import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionsKeyboardNavigationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    func testMovingDownSelectsRowsInOrderAndStopsAtLastRow() throws {
        let controller = makeInteractionController()
        let recorder = InteractionRecorder()
        controller.selectionHandler = { recorder.select($0?.data as? Int) }
        XCTAssertNil(controller.selectedSuggestion)

        for index in 0..<3 {
            controller.moveDown(nil)
            XCTAssertEqual(controller.selectedSuggestion?.data as? Int, index)
            try assertHighlightedRow(index, in: controller)
        }
        controller.moveDown(nil)

        XCTAssertEqual(controller.selectedSuggestion?.data as? Int, 2)
        XCTAssertEqual(recorder.selections, [0, 1, 2])
        try assertHighlightedRow(2, in: controller)
    }

    func testMovingUpSelectsPreviousRowsThenClearsSelection() throws {
        let controller = makeInteractionController()
        for _ in 0..<3 { controller.moveDown(nil) }
        let recorder = InteractionRecorder()
        controller.selectionHandler = { recorder.select($0?.data as? Int) }

        controller.moveUp(nil)
        XCTAssertEqual(controller.selectedSuggestion?.data as? Int, 1)
        try assertHighlightedRow(1, in: controller)
        controller.moveUp(nil)
        XCTAssertEqual(controller.selectedSuggestion?.data as? Int, 0)
        try assertHighlightedRow(0, in: controller)
        controller.moveUp(nil)
        controller.moveUp(nil)

        XCTAssertNil(controller.selectedSuggestion)
        try assertHighlightedRow(nil, in: controller)
        XCTAssertEqual(recorder.selections, [1, 0, nil])
    }

    func testMovingUpWithoutSelectionDoesNotSelectLastRowOrNotify() throws {
        let controller = makeInteractionController()
        let recorder = InteractionRecorder()
        controller.selectionHandler = { recorder.select($0?.data as? Int) }

        controller.moveUp(nil)

        XCTAssertNil(controller.selectedSuggestion)
        XCTAssertTrue(recorder.selections.isEmpty)
        try assertHighlightedRow(nil, in: controller)
    }

    func testMovingDownAfterClearingSelectionRestartsAtFirstRow() throws {
        let controller = makeInteractionController()
        controller.moveDown(nil)
        controller.moveUp(nil)

        controller.moveDown(nil)

        XCTAssertEqual(controller.selectedSuggestion?.data as? Int, 0)
        try assertHighlightedRow(0, in: controller)
    }

    func testEmptySuggestionsIgnoreBothNavigationCommands() {
        let controller = makeInteractionController(count: 0)
        let recorder = InteractionRecorder()
        controller.selectionHandler = { recorder.select($0?.data as? Int) }

        controller.moveDown(nil)
        controller.moveUp(nil)

        XCTAssertNil(controller.selectedSuggestion)
        XCTAssertTrue(recorder.selections.isEmpty)
    }

    func testSingleSuggestionCanBeSelectedAndClearedWithoutHandlers() throws {
        let controller = makeInteractionController(count: 1)

        controller.moveDown(nil)
        controller.moveDown(nil)
        XCTAssertEqual(controller.selectedSuggestion?.data as? Int, 0)
        try assertHighlightedRow(0, in: controller)
        controller.moveUp(nil)

        XCTAssertNil(controller.selectedSuggestion)
        try assertHighlightedRow(nil, in: controller)
    }
}

final class SuggestionsMouseInteractionTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    func testEnteringTrackingAreaSelectsItsSuggestionAndExitingClearsIt() throws {
        let controller = makeInteractionController()
        let contentView = try XCTUnwrap(controller.window?.contentView)
        let row = try XCTUnwrap(controller.viewControllers[1].view as? SuggestionView)
        let area = try XCTUnwrap(contentView.trackingAreas.first {
            ($0.userInfo?.values.first as? NSView) === row
        })
        let event = TrackingAreaEvent()
        event.area = area
        let recorder = InteractionRecorder()
        controller.selectionHandler = { recorder.select($0?.data as? Int) }

        controller.mouseEntered(with: event)

        XCTAssertEqual(controller.selectedSuggestion?.data as? Int, 1)
        try assertHighlightedRow(1, in: controller)
        controller.mouseExited(with: event)
        XCTAssertNil(controller.selectedSuggestion)
        try assertHighlightedRow(nil, in: controller)
        XCTAssertEqual(recorder.selections, [1, nil])
    }

    func testEnteringWithoutTrackingAreaClearsExistingSelection() throws {
        let controller = makeInteractionController()
        controller.moveDown(nil)
        let recorder = InteractionRecorder()
        controller.selectionHandler = { recorder.select($0?.data as? Int) }

        controller.mouseEntered(with: TrackingAreaEvent())

        XCTAssertNil(controller.selectedSuggestion)
        try assertHighlightedRow(nil, in: controller)
        XCTAssertEqual(recorder.selections, [nil])
    }

    func testDraggingAcrossRowsUpdatesSelectionAndHighlight() throws {
        let controller = makeInteractionController()
        let contentView = try XCTUnwrap(controller.window?.contentView)
        let recorder = InteractionRecorder()
        controller.selectionHandler = { recorder.select($0?.data as? Int) }

        for index in [2, 0, 1] {
            let row = controller.viewControllers[index].view
            let point = NSPoint(x: row.frame.midX, y: contentView.frame.height - row.frame.midY)
            controller.mouseDragged(with: try mouseEvent(.leftMouseDragged, at: point))
            XCTAssertEqual(controller.selectedSuggestion?.data as? Int, index)
            try assertHighlightedRow(index, in: controller)
        }

        XCTAssertEqual(recorder.selections, [2, 0, 1])
    }

    func testDraggingOutsideEitherHorizontalEdgeClearsSelection() throws {
        let controller = makeInteractionController()
        let contentView = try XCTUnwrap(controller.window?.contentView)
        let row = controller.viewControllers[0].view
        let y = contentView.frame.height - row.frame.midY
        let recorder = InteractionRecorder()
        controller.selectionHandler = { recorder.select($0?.data as? Int) }

        for x in [-1, contentView.bounds.maxX + 1] {
            controller.moveDown(nil)
            controller.mouseDragged(with: try mouseEvent(.leftMouseDragged, at: NSPoint(x: x, y: y)))
            XCTAssertNil(controller.selectedSuggestion)
            try assertHighlightedRow(nil, in: controller)
        }

        XCTAssertEqual(recorder.selections, [0, nil, 0, nil])
    }

    func testDraggingIntoTopOrBottomPaddingClearsSelection() throws {
        let controller = makeInteractionController()
        let contentView = try XCTUnwrap(controller.window?.contentView)

        for y in [1, contentView.frame.height - 1] {
            controller.moveDown(nil)
            let point = NSPoint(x: contentView.bounds.midX, y: y)
            controller.mouseDragged(with: try mouseEvent(.leftMouseDragged, at: point))

            XCTAssertNil(controller.selectedSuggestion)
            try assertHighlightedRow(nil, in: controller)
        }
    }

    func testDraggingWithoutSuggestionsContentViewClearsSelection() throws {
        let controller = makeInteractionController()
        controller.moveDown(nil)
        controller.window?.contentView = NSView()

        controller.mouseDragged(with: try mouseEvent(.leftMouseDragged))

        XCTAssertNil(controller.selectedSuggestion)
        try assertHighlightedRow(nil, in: controller)
    }

    func testMouseUpCommitsEditingSendsActionConfirmsSelectionThenCancels() throws {
        let recorder = InteractionRecorder()
        let controller = MouseUpController(recorder: recorder)
        populateInteractionController(controller)
        let textField = MouseUpTextField(recorder: recorder)
        let target = MouseUpActionTarget(recorder: recorder)
        textField.target = target
        textField.action = #selector(MouseUpActionTarget.accept(_:))
        controller.parentTextField = textField
        controller.moveDown(nil)
        controller.moveDown(nil)
        controller.confirmationHandler = {
            recorder.select($0?.data as? Int)
            recorder.record("confirm")
        }

        controller.mouseUp(with: try mouseEvent(.leftMouseUp))

        XCTAssertEqual(recorder.events, ["validate", "abort", "sendAction", "action", "confirm", "cancel"])
        XCTAssertEqual(recorder.selections, [1])
    }

    func testMouseUpWithoutParentOrSelectionConfirmsNilAndCancels() throws {
        let recorder = InteractionRecorder()
        let controller = MouseUpController(recorder: recorder)
        controller.confirmationHandler = {
            recorder.select($0?.data as? Int)
            recorder.record("confirm")
        }

        controller.mouseUp(with: try mouseEvent(.leftMouseUp))

        XCTAssertEqual(recorder.selections, [nil])
        XCTAssertEqual(recorder.events, ["confirm", "cancel"])
    }
}

private func makeInteractionController(count: Int = 3) -> SuggestionsWindowController {
    let controller = SuggestionsWindowController()
    populateInteractionController(controller, count: count)
    return controller
}

private func populateInteractionController(_ controller: SuggestionsWindowController, count: Int = 3) {
    controller.window?.setFrame(NSRect(x: 0, y: 0, width: 240, height: 100), display: false)
    let dataSource = MockSuggestionsDataSource()
    // Identical labels ensure callbacks and selection preserve the row's actual payload.
    dataSource.suggestions = (0..<count).map {
        Suggestion(imageName: "", displayText: "Suggestion", data: $0)
    }
    controller.dataSource = dataSource
}

private func assertHighlightedRow(
    _ selectedIndex: Int?, in controller: SuggestionsWindowController,
    file: StaticString = #filePath, line: UInt = #line
) throws {
    for (index, viewController) in controller.viewControllers.enumerated() {
        let row = try XCTUnwrap(viewController.view as? SuggestionView, file: file, line: line)
        XCTAssertEqual(row.highlighted, index == selectedIndex, file: file, line: line)
    }
}

private func mouseEvent(_ type: NSEvent.EventType, at point: NSPoint = .zero) throws -> NSEvent {
    try XCTUnwrap(NSEvent.mouseEvent(
        with: type, location: point, modifierFlags: [], timestamp: 0,
        windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 0
    ))
}

private final class TrackingAreaEvent: NSEvent {
    var area: NSTrackingArea?
    override var trackingArea: NSTrackingArea? { area }
}

private final class InteractionRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storedSelections: [Int?] = []
    private var storedEvents: [String] = []

    var selections: [Int?] {
        lock.lock()
        defer { lock.unlock() }
        return storedSelections
    }

    var events: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storedEvents
    }

    func select(_ value: Int?) {
        lock.lock()
        defer { lock.unlock() }
        storedSelections.append(value)
    }

    func record(_ value: String) {
        lock.lock()
        defer { lock.unlock() }
        storedEvents.append(value)
    }
}

private final class MouseUpController: SuggestionsWindowController {
    let recorder: InteractionRecorder

    init(recorder: InteractionRecorder) {
        self.recorder = recorder
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func cancelSuggestions() {
        recorder.record("cancel")
        super.cancelSuggestions()
    }
}

private final class MouseUpTextField: NSTextField {
    let recorder: InteractionRecorder

    init(recorder: InteractionRecorder) {
        self.recorder = recorder
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func validateEditing() {
        recorder.record("validate")
    }

    override func abortEditing() -> Bool {
        recorder.record("abort")
        return true
    }

    override func sendAction(_ action: Selector?, to target: Any?) -> Bool {
        recorder.record("sendAction")
        return super.sendAction(action, to: target)
    }
}

private final class MouseUpActionTarget: NSObject {
    let recorder: InteractionRecorder

    init(recorder: InteractionRecorder) {
        self.recorder = recorder
    }

    @objc func accept(_ sender: Any) {
        recorder.record("action")
    }
}
