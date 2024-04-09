//
//  SuggestionsWindowControllerTests.swift
//  
//
//  Created by Claudio Cambra on 9/4/24.
//

import XCTest
@testable import SuggestionsTextFieldKit

class SuggestionsWindowControllerTests: XCTestCase {
    var windowController: SuggestionsWindowController!

    override func setUpWithError() throws {
        try super.setUpWithError()
        windowController = SuggestionsWindowController()
    }

    override func tearDownWithError() throws {
        windowController = nil
        try super.tearDownWithError()
    }

    private func createMockSuggestion() -> Suggestion {
        Suggestion(imageName: "testtube.2", displayText: "Test", data: ["data": "data"])
    }

    func testInitialization() throws {
        let window = windowController.window
        XCTAssertNotNil(window, "Controller window should be valid")
        XCTAssertNotNil(
            window as? SuggestionsWindow,
            "Controller window should be a SuggestionsWindow"
        )
        XCTAssertNotNil(
            window?.contentView as? SuggestionsWindowContentView,
            "Controller window content view should be a SuggestionsWindowContentView"
        )
    }

    func testLayoutSuggestionsOnDataSourceUpdate() {
        // Verify the suggestions layout is empty
        XCTAssertTrue(windowController.viewControllers.isEmpty)

        let mockDataSource = MockSuggestionsDataSource()
        mockDataSource.suggestions = [createMockSuggestion(), createMockSuggestion()]
        windowController.dataSource = mockDataSource

        XCTAssertEqual(windowController.viewControllers.count, mockDataSource.suggestions.count)

        for (index, viewController) in windowController.viewControllers.enumerated() {
            let suggestionView = viewController.view as? SuggestionView
            XCTAssertNotNil(suggestionView, "View should be a SuggestionView")
            let vcSuggestion = viewController.representedObject as? Suggestion
            XCTAssertNotNil(vcSuggestion, "View controller should have a suggestion as rep obj")
            let matchingSuggestion = mockDataSource.suggestions[index]
            XCTAssertEqual(vcSuggestion!.displayText, matchingSuggestion.displayText)
            XCTAssertEqual(vcSuggestion!.imageName, matchingSuggestion.imageName)
            XCTAssertEqual(
                vcSuggestion!.data as! [String: String],
                matchingSuggestion.data as! [String: String]
            )
        }

        // Check the window controller updates the suggestions
        mockDataSource.suggestions.append(createMockSuggestion())
        NotificationCenter.default.post(
            name: SuggestionsChangedNotificationName, object: mockDataSource
        )
        XCTAssertEqual(windowController.viewControllers.count, mockDataSource.suggestions.count)
    }
}

