import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionsWindowLayoutTests: XCTestCase {
    private var controller: SuggestionsWindowController!
    private var dataSource: MockSuggestionsDataSource!

    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
        controller = SuggestionsWindowController()
        controller.window?.setFrame(NSRect(x: 100, y: 300, width: 320, height: 200), display: false)
        dataSource = MockSuggestionsDataSource()
    }

    override func tearDown() {
        controller.cancelSuggestions()
        controller = nil
        dataSource = nil
        super.tearDown()
    }

    func testRowsPreserveSuggestionOrderAndPayloads() throws {
        dataSource.suggestions = suggestions(count: 3)
        controller.dataSource = dataSource

        XCTAssertEqual(controller.viewControllers.count, 3)
        let contentView = try XCTUnwrap(controller.window?.contentView)
        for (index, rowController) in controller.viewControllers.enumerated() {
            let suggestion = try XCTUnwrap(rowController.representedObject as? Suggestion)
            let row = try XCTUnwrap(rowController.view as? SuggestionView)
            XCTAssertEqual(suggestion.displayText, "Result \(index)")
            XCTAssertEqual(suggestion.data as? Int, index)
            XCTAssertEqual(row.label.stringValue, suggestion.displayText)
            XCTAssertTrue(row.superview === contentView)
        }
    }

    func testRowsFillWindowWidthWithMarginsAndDoNotOverlap() throws {
        let originalTop = try XCTUnwrap(controller.window).frame.maxY
        dataSource.suggestions = suggestions(count: 3)
        controller.dataSource = dataSource

        let contentView = try XCTUnwrap(controller.window?.contentView)
        let rows = controller.viewControllers.map(\.view)
        XCTAssertEqual(contentView.frame.height, 72, accuracy: 0.01)
        XCTAssertEqual(controller.window!.frame.maxY, originalTop, accuracy: 0.01)
        for (index, row) in rows.enumerated() {
            XCTAssertEqual(row.frame.minX, 0, accuracy: 0.01)
            XCTAssertEqual(row.frame.width, contentView.bounds.width, accuracy: 0.01)
            XCTAssertEqual(row.frame.height, 20, accuracy: 0.01)
            XCTAssertEqual(row.frame.minY, 6 + CGFloat(index) * 20, accuracy: 0.01)
        }
        XCTAssertEqual(contentView.bounds.maxY - rows.last!.frame.maxY, 6, accuracy: 0.01)
    }

    func testEachRowHasItsOwnTrackingArea() throws {
        dataSource.suggestions = suggestions(count: 3)
        controller.dataSource = dataSource

        let contentView = try XCTUnwrap(controller.window?.contentView)
        XCTAssertEqual(contentView.trackingAreas.count, 3)
        for (rowController, area) in zip(controller.viewControllers, contentView.trackingAreas) {
            let trackedView = area.userInfo?["whichImageView"] as? NSView
            XCTAssertTrue(trackedView === rowController.view)
            XCTAssertTrue(area.owner as? SuggestionsWindowController === controller)
            XCTAssertEqual(area.rect, contentView.convert(rowController.view.bounds, from: rowController.view))
            XCTAssertTrue(area.options.contains([.enabledDuringMouseDrag, .mouseEnteredAndExited, .activeInActiveApp]))
        }
    }

    func testNotificationReplacesRowsAndTrackingAreasAndClearsSelection() throws {
        dataSource.suggestions = suggestions(count: 3)
        controller.dataSource = dataSource
        controller.moveDown(nil)
        let oldRows = try controller.viewControllers.map { try XCTUnwrap($0.view as? SuggestionView) }
        let contentView = try XCTUnwrap(controller.window?.contentView)
        let oldTrackingAreas = contentView.trackingAreas
        XCTAssertTrue(oldRows[0].highlighted)

        dataSource.suggestions = [Suggestion(imageName: "", displayText: "Replacement", data: 99)]
        postSuggestionsChanged()

        XCTAssertNil(controller.selectedSuggestion)
        XCTAssertTrue(oldRows.allSatisfy { $0.superview == nil && !$0.highlighted })
        XCTAssertEqual(controller.viewControllers.count, 1)
        XCTAssertEqual(contentView.subviews.compactMap { $0 as? SuggestionView }.count, 1)
        XCTAssertEqual(contentView.trackingAreas.count, 1)
        XCTAssertFalse(contentView.trackingAreas.contains { area in oldTrackingAreas.contains { $0 === area } })
        let row = try XCTUnwrap(controller.viewControllers.first?.view as? SuggestionView)
        XCTAssertEqual(row.label.stringValue, "Replacement")
    }

    func testEmptyUpdateRemovesRowsAndShrinksWindowKeepingTopEdge() throws {
        dataSource.suggestions = suggestions(count: 3)
        controller.dataSource = dataSource
        controller.moveDown(nil)
        let window = try XCTUnwrap(controller.window)
        let originalTop = window.frame.maxY

        dataSource.suggestions = []
        postSuggestionsChanged()

        XCTAssertTrue(controller.viewControllers.isEmpty)
        XCTAssertTrue(window.contentView!.trackingAreas.isEmpty)
        XCTAssertTrue(window.contentView!.subviews.compactMap { $0 as? SuggestionView }.isEmpty)
        XCTAssertNil(controller.selectedSuggestion)
        XCTAssertEqual(window.frame.height, 12, accuracy: 0.01)
        XCTAssertEqual(window.frame.maxY, originalTop, accuracy: 0.01)
    }

    func testNotificationFromUnrelatedDataSourceDoesNotRebuildRows() throws {
        dataSource.suggestions = suggestions(count: 1)
        controller.dataSource = dataSource
        let originalRow = try XCTUnwrap(controller.viewControllers.first)
        let otherDataSource = MockSuggestionsDataSource()
        otherDataSource.suggestions = suggestions(count: 4)

        NotificationCenter.default.post(name: SuggestionsChangedNotificationName, object: otherDataSource)

        XCTAssertEqual(controller.viewControllers.count, 1)
        XCTAssertTrue(controller.viewControllers.first === originalRow)
    }

    func testReplacingDataSourceImmediatelyDisplaysItsSuggestions() throws {
        dataSource.suggestions = suggestions(count: 3)
        controller.dataSource = dataSource
        controller.moveDown(nil)
        let oldRows = controller.viewControllers.map(\.view)
        let replacement = MockSuggestionsDataSource()
        replacement.suggestions = [Suggestion(imageName: "", displayText: "New source", data: 42)]

        controller.dataSource = replacement

        XCTAssertTrue(controller.dataSource as? MockSuggestionsDataSource === replacement)
        XCTAssertTrue(oldRows.allSatisfy { $0.superview == nil })
        XCTAssertNil(controller.selectedSuggestion)
        XCTAssertEqual(controller.viewControllers.count, 1)
        XCTAssertEqual((controller.viewControllers.first?.representedObject as? Suggestion)?.data as? Int, 42)
    }

    private func suggestions(count: Int) -> [Suggestion] {
        (0..<count).map { Suggestion(imageName: "", displayText: "Result \($0)", data: $0) }
    }

    private func postSuggestionsChanged() {
        NotificationCenter.default.post(name: SuggestionsChangedNotificationName, object: dataSource)
    }
}
