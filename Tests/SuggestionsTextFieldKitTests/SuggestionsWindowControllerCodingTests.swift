import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

class SuggestionsWindowControllerCodingTests: XCTestCase {
    func testKeyedArchiveRestoresControllerSettingsWithoutLoadingWindow() throws {
        _ = NSApplication.shared
        let controller = SuggestionsWindowController()
        controller.windowFrameAutosaveName = "SuggestionsWindowControllerCodingTests"
        XCTAssertTrue(controller.isWindowLoaded)
        let archive = try NSKeyedArchiver.archivedData(
            withRootObject: controller, requiringSecureCoding: false
        )

        let decoder = try NSKeyedUnarchiver(forReadingFrom: archive)
        decoder.requiresSecureCoding = false
        defer { decoder.finishDecoding() }
        let decoded = try XCTUnwrap(
            decoder.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
                as? SuggestionsWindowController
        )

        XCTAssertEqual(decoded.windowFrameAutosaveName, controller.windowFrameAutosaveName)
        // NSWindowController archives its configuration, rather than the live popup window.
        XCTAssertFalse(decoded.isWindowLoaded)
        XCTAssertNil(decoded.window)
    }
}
