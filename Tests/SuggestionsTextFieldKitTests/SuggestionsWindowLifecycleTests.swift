import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionsWindowLifecycleTests: XCTestCase {
    private var controller: SuggestionsWindowController!
    private var parentWindow: NSWindow!
    private var textField: NSTextField!

    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
        parentWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 200, width: 480, height: 240),
            styleMask: .titled, backing: .buffered, defer: false
        )
        parentWindow.isReleasedWhenClosed = false
        let container = NSView(frame: NSRect(x: 30, y: 40, width: 400, height: 150))
        parentWindow.contentView?.addSubview(container)
        textField = NSTextField(frame: NSRect(x: 20, y: 60, width: 260, height: 24))
        container.addSubview(textField)
        parentWindow.orderFront(nil)
        controller = LifecycleTrackingWindowController()
        controller.window?.setFrame(NSRect(x: 100, y: 200, width: 320, height: 100), display: false)
        controller.parentTextField = textField
        let dataSource = MockSuggestionsDataSource()
        dataSource.suggestions = [
            Suggestion(imageName: "", displayText: "First", data: 1),
            Suggestion(imageName: "", displayText: "Second", data: 2),
        ]
        controller.dataSource = dataSource
    }

    override func tearDown() {
        controller.cancelSuggestions()
        parentWindow.orderOut(nil)
        controller = nil
        textField = nil
        parentWindow = nil
        super.tearDown()
    }

    func testRepositionAlignsBelowTextFieldThroughNestedSuperview() throws {
        let window = try XCTUnwrap(controller.window)
        let originalHeight = window.frame.height
        let textFieldFrame = textField.convert(textField.bounds, to: nil)
        let screenFrame = parentWindow.convertToScreen(textFieldFrame)

        controller.repositionWindow()

        XCTAssertEqual(window.frame.width, textField.frame.width + 10, accuracy: 0.01)
        XCTAssertEqual(window.frame.minX, screenFrame.minX - 5, accuracy: 0.01)
        XCTAssertEqual(window.frame.maxY, screenFrame.minY, accuracy: 0.01)
        XCTAssertEqual(window.frame.height, originalHeight, accuracy: 0.01)
    }

    func testRepositionWithoutAttachedTextFieldLeavesFrameUnchanged() throws {
        let window = try XCTUnwrap(controller.window)
        let originalFrame = window.frame
        controller.parentTextField = NSTextField()

        controller.repositionWindow()

        XCTAssertEqual(window.frame, originalFrame)
    }

    func testEnableAttachesPopupAndRelayoutsRowsForTextFieldWidth() throws {
        textField.frame.size.width = 340

        controller.enableSuggestions()

        let window = try XCTUnwrap(controller.window as? SuggestionsWindow)
        XCTAssertTrue(window.parent === parentWindow)
        XCTAssertTrue(parentWindow.childWindows?.contains { $0 === window } == true)
        XCTAssertTrue(window.isVisible)
        XCTAssertNotNil(window.parentElement)
        XCTAssertEqual(window.frame.width, 350, accuracy: 0.01)
        XCTAssertEqual(controller.viewControllers.count, 2)
        for rowController in controller.viewControllers {
            XCTAssertEqual(rowController.view.frame.width, 350, accuracy: 0.01)
        }
    }

    func testEnableWithoutParentWindowDoesNotShowPopup() throws {
        controller.parentTextField = NSTextField()

        controller.enableSuggestions()

        let window = try XCTUnwrap(controller.window)
        XCTAssertFalse(window.isVisible)
        XCTAssertNil(window.parent)
        XCTAssertEqual(controller.viewControllers.count, 2)
    }

    func testCancelHidesPopupAndDisconnectsParent() throws {
        controller.enableSuggestions()
        let window = try XCTUnwrap(controller.window as? SuggestionsWindow)

        controller.cancelSuggestions()
        controller.cancelSuggestions()

        XCTAssertFalse(window.isVisible)
        XCTAssertNil(window.parent)
        XCTAssertNil(window.parentElement)
        XCTAssertFalse(parentWindow.childWindows?.contains { $0 === window } == true)
    }

    func testLosingParentWindowKeyStatusCancelsPopup() throws {
        controller.enableSuggestions()
        let window = try XCTUnwrap(controller.window)
        XCTAssertTrue(window.isVisible)

        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: parentWindow)

        XCTAssertFalse(window.isVisible)
        XCTAssertNil(window.parent)
    }

    func testLosingUnrelatedWindowKeyStatusKeepsPopupVisible() throws {
        let unrelatedWindow = NSWindow(
            contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: true
        )
        controller.enableSuggestions()
        let window = try XCTUnwrap(controller.window)

        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: unrelatedWindow)

        XCTAssertTrue(window.isVisible)
        XCTAssertTrue(window.parent === parentWindow)
    }

    func testCancellationRemovesParentWindowFocusObserver() throws {
        let trackingController = try XCTUnwrap(controller as? LifecycleTrackingWindowController)
        controller.enableSuggestions()
        controller.cancelSuggestions()
        let cancelCount = trackingController.cancelCount

        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: parentWindow)

        XCTAssertEqual(trackingController.cancelCount, cancelCount)
    }

    func testPopupCanBeEnabledAgainAfterCancellation() throws {
        controller.enableSuggestions()
        controller.cancelSuggestions()

        controller.enableSuggestions()

        let window = try XCTUnwrap(controller.window)
        XCTAssertTrue(window.isVisible)
        XCTAssertTrue(window.parent === parentWindow)
        NotificationCenter.default.post(name: NSWindow.didResignKeyNotification, object: parentWindow)
        XCTAssertFalse(window.isVisible)
    }
}

private final class LifecycleTrackingWindowController: SuggestionsWindowController {
    private(set) var cancelCount = 0

    override func cancelSuggestions() {
        cancelCount += 1
        super.cancelSuggestions()
    }
}
