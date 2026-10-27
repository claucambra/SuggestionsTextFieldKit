import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionsDataSourceObservationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    func testReplacingDataSourceStopsOldNotificationsFromClearingNewSelection() throws {
        let controller = makeController()
        let oldSource = ObservationDataSource()
        let currentSource = ObservationDataSource()
        controller.dataSource = oldSource
        controller.dataSource = currentSource
        controller.moveDown(nil)
        let currentRow = try XCTUnwrap(controller.viewControllers.first)
        currentSource.readCount = 0

        NotificationCenter.default.post(name: SuggestionsChangedNotificationName, object: oldSource)

        XCTAssertEqual(currentSource.readCount, 0)
        XCTAssertTrue(controller.viewControllers.first === currentRow)
        XCTAssertEqual(controller.selectedSuggestion?.data as? Int, 1)
    }

    func testReassigningSameDataSourceRegistersOnlyOneObserver() {
        let controller = makeController()
        let source = ObservationDataSource()
        for _ in 0..<3 { controller.dataSource = source }
        source.readCount = 0

        NotificationCenter.default.post(name: SuggestionsChangedNotificationName, object: source)

        XCTAssertEqual(source.readCount, 1)
        XCTAssertEqual(controller.viewControllers.count, 1)
    }

    func testReplacementSourceStillRefreshesItsRows() throws {
        let controller = makeController()
        controller.dataSource = ObservationDataSource()
        let source = ObservationDataSource()
        controller.dataSource = source
        let oldRow = try XCTUnwrap(controller.viewControllers.first?.view)
        source.results = [Suggestion(imageName: "", displayText: "Updated", data: 2)]
        source.readCount = 0

        NotificationCenter.default.post(name: SuggestionsChangedNotificationName, object: source)

        XCTAssertEqual(source.readCount, 1)
        XCTAssertNil(oldRow.superview)
        XCTAssertEqual((controller.viewControllers.first?.representedObject as? Suggestion)?.data as? Int, 2)
    }

    func testClearingDataSourceRemovesObservation() {
        let controller = makeController()
        let source = ObservationDataSource()
        controller.dataSource = source
        controller.dataSource = nil
        let rowsAfterClearing = controller.viewControllers
        source.readCount = 0

        NotificationCenter.default.post(name: SuggestionsChangedNotificationName, object: source)

        XCTAssertEqual(source.readCount, 0)
        XCTAssertEqual(controller.viewControllers, rowsAfterClearing)
    }

    func testDataSourceObservationDoesNotRetainControllerOrSource() {
        weak var weakController: SuggestionsWindowController?
        weak var weakSource: ObservationDataSource?
        autoreleasepool {
            let controller = makeController()
            let source = ObservationDataSource()
            weakController = controller
            weakSource = source
            controller.dataSource = source
            XCTAssertNotNil(weakController)
            XCTAssertNotNil(weakSource)
        }

        XCTAssertNil(weakController)
        XCTAssertNil(weakSource)
    }

    func testNotificationsAfterControllerReleaseDoNotReadDataSource() {
        let source = ObservationDataSource()
        weak var weakController: SuggestionsWindowController?
        autoreleasepool {
            let controller = makeController()
            weakController = controller
            controller.dataSource = source
        }
        XCTAssertNil(weakController)
        source.readCount = 0

        NotificationCenter.default.post(name: SuggestionsChangedNotificationName, object: source)

        XCTAssertEqual(source.readCount, 0)
    }

    private func makeController() -> SuggestionsWindowController {
        let controller = SuggestionsWindowController()
        controller.window?.setFrame(NSRect(x: 100, y: 100, width: 240, height: 100), display: false)
        return controller
    }
}

private final class ObservationDataSource: NSObject, SuggestionsDataSource {
    var inputString = ""
    var readCount = 0
    var results = [Suggestion(imageName: "", displayText: "Result", data: 1)]

    var suggestions: [Suggestion] {
        readCount += 1
        return results
    }
}
