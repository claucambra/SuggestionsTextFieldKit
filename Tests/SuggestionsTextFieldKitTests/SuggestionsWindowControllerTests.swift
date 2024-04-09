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
}

