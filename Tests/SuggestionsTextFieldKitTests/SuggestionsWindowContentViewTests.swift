import AppKit
import XCTest
@testable import SuggestionsTextFieldKit

final class SuggestionsWindowContentViewTests: XCTestCase {
    override func setUp() {
        super.setUp()
        _ = NSApplication.shared
    }

    func testEmptyContentExposesAnEnabledVerticalListWithoutChildren() {
        let contentView = SuggestionsWindowContentView()

        XCTAssertFalse(contentView.accessibilityIsIgnored())
        XCTAssertTrue(contentView.isAccessibilityEnabled())
        XCTAssertEqual(contentView.accessibilityOrientation(), .vertical)
        XCTAssertEqual(contentView.accessibilityChildren()?.count, 0)
        XCTAssertEqual(contentView.accessibilityVisibleChildren()?.count, 0)
        XCTAssertEqual(contentView.accessibilitySelectedChildren()?.count, 0)
        XCTAssertTrue(contentView.isFlipped)
    }

    func testAccessibilityChildrenIncludeOnlyDirectSuggestionRowsInOrder() {
        let contentView = SuggestionsWindowContentView()
        let first = SuggestionView()
        let second = SuggestionView()
        let decoration = NSView()
        decoration.addSubview(SuggestionView())
        contentView.addSubview(first)
        contentView.addSubview(decoration)
        contentView.addSubview(second)

        XCTAssertEqual(contentView.accessibilityChildren() as? [SuggestionView], [first, second])
        XCTAssertEqual(contentView.accessibilityVisibleChildren() as? [SuggestionView], [first, second])

        first.removeFromSuperview()

        XCTAssertEqual(contentView.accessibilityChildren() as? [SuggestionView], [second])
        XCTAssertEqual(contentView.accessibilityVisibleChildren() as? [SuggestionView], [second])
    }

    func testAccessibilitySelectionTracksHighlightChangesAndRemovedRows() {
        let contentView = SuggestionsWindowContentView()
        let first = SuggestionView()
        let second = SuggestionView()
        let third = SuggestionView()
        [first, second, third].forEach { contentView.addSubview($0) }
        first.highlighted = true
        third.highlighted = true

        XCTAssertEqual(contentView.accessibilitySelectedChildren() as? [SuggestionView], [first, third])

        first.highlighted = false
        second.highlighted = true
        third.removeFromSuperview()

        XCTAssertEqual(contentView.accessibilitySelectedChildren() as? [SuggestionView], [second])

        second.highlighted = false

        XCTAssertEqual(contentView.accessibilitySelectedChildren()?.count, 0)
    }

    func testBackgroundFillsContentWhenResized() throws {
        let contentView = SuggestionsWindowContentView(
            frame: NSRect(x: 0, y: 0, width: 200, height: 80)
        )
        let background = try XCTUnwrap(contentView.subviews.first as? NSVisualEffectView)
        contentView.layoutSubtreeIfNeeded()
        XCTAssertEqual(background.frame, contentView.bounds)

        contentView.setFrameSize(NSSize(width: 320, height: 140))
        contentView.layoutSubtreeIfNeeded()

        XCTAssertEqual(background.frame, contentView.bounds)
        XCTAssertEqual(background.blendingMode, .withinWindow)
        XCTAssertEqual(background.material, .menu)
        XCTAssertEqual(background.state, .active)
    }

    func testDecodingContentViewRestoresBackgroundAndListBehavior() throws {
        let original = SuggestionsWindowContentView(
            frame: NSRect(x: 10, y: 20, width: 240, height: 80)
        )
        original.layoutSubtreeIfNeeded()
        let archive = try NSKeyedArchiver.archivedData(
            withRootObject: original, requiringSecureCoding: false
        )
        let decoder = try NSKeyedUnarchiver(forReadingFrom: archive)
        decoder.requiresSecureCoding = false
        defer { decoder.finishDecoding() }
        let decoded = try XCTUnwrap(
            decoder.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
                as? SuggestionsWindowContentView
        )
        let background = try XCTUnwrap(decoded.subviews.first as? NSVisualEffectView)
        decoded.needsLayout = true
        decoded.layoutSubtreeIfNeeded()

        XCTAssertEqual(decoded.frame, original.frame)
        XCTAssertEqual(background.frame, decoded.bounds)
        XCTAssertEqual(background.material, .menu)
        XCTAssertTrue(decoded.isFlipped)
        XCTAssertTrue(decoded.isAccessibilityEnabled())
        XCTAssertEqual(decoded.accessibilityChildren()?.count, 0)

        decoded.setFrameSize(NSSize(width: 320, height: 140))
        decoded.layoutSubtreeIfNeeded()
        XCTAssertEqual(background.frame, decoded.bounds)
    }

    func testDecodingReplacesArchivedBackgroundConstraintsWithoutDuplicatingBackground() throws {
        let original = SuggestionsWindowContentView(
            frame: NSRect(x: 0, y: 0, width: 240, height: 80)
        )
        let originalBackground = try XCTUnwrap(original.subviews.first as? NSVisualEffectView)
        original.constraints.forEach { $0.shouldBeArchived = true }
        let unrelatedConstraint = original.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
        unrelatedConstraint.identifier = "Unrelated constraint"
        unrelatedConstraint.shouldBeArchived = true
        unrelatedConstraint.isActive = true
        let reverseConstraint = original.widthAnchor.constraint(equalTo: originalBackground.widthAnchor)
        reverseConstraint.shouldBeArchived = true
        reverseConstraint.isActive = true
        original.addSubview(NSView())
        original.layoutSubtreeIfNeeded()
        let archive = try NSKeyedArchiver.archivedData(
            withRootObject: original, requiringSecureCoding: false
        )
        let decoder = try NSKeyedUnarchiver(forReadingFrom: archive)
        decoder.requiresSecureCoding = false
        defer { decoder.finishDecoding() }

        let decoded = try XCTUnwrap(
            decoder.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
                as? SuggestionsWindowContentView
        )
        let backgrounds = decoded.subviews.compactMap { $0 as? NSVisualEffectView }
        let background = try XCTUnwrap(backgrounds.first)
        XCTAssertEqual(backgrounds.count, 1)
        XCTAssertEqual(decoded.constraints.filter { $0.identifier == "Unrelated constraint" }.count, 1)
        let backgroundConstraints = decoded.constraints.filter { constraint in
            [constraint.firstItem, constraint.secondItem].contains { ($0 as? NSView) === background }
        }
        XCTAssertEqual(backgroundConstraints.count, 4)

        decoded.setFrameSize(NSSize(width: 320, height: 140))
        decoded.layoutSubtreeIfNeeded()

        XCTAssertEqual(background.frame, decoded.bounds)
    }

    func testDecodingMissingBackgroundCreatesOneThatResizesWithContent() throws {
        let original = SuggestionsWindowContentView(
            frame: NSRect(x: 0, y: 0, width: 240, height: 80)
        )
        original.subviews.forEach { $0.removeFromSuperview() }
        let archive = try NSKeyedArchiver.archivedData(
            withRootObject: original, requiringSecureCoding: false
        )
        let decoder = try NSKeyedUnarchiver(forReadingFrom: archive)
        decoder.requiresSecureCoding = false
        defer { decoder.finishDecoding() }

        let decoded = try XCTUnwrap(
            decoder.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
                as? SuggestionsWindowContentView
        )
        let backgrounds = decoded.subviews.compactMap { $0 as? NSVisualEffectView }
        let background = try XCTUnwrap(backgrounds.first)
        XCTAssertEqual(backgrounds.count, 1)
        decoded.setFrameSize(NSSize(width: 320, height: 140))
        decoded.layoutSubtreeIfNeeded()

        XCTAssertEqual(background.frame, decoded.bounds)
        XCTAssertEqual(background.blendingMode, .withinWindow)
        XCTAssertEqual(background.material, .menu)
        XCTAssertEqual(background.state, .active)
    }

    func testDrawingUsesRoundedCornersAndFillsCenter() throws {
        let view = SuggestionsWindowContentView(
            frame: NSRect(x: 0, y: 0, width: 40, height: 40)
        )
        view.cornerRadius = 12

        let bitmap = try renderBackground(of: view)

        XCTAssertEqual(try XCTUnwrap(bitmap.colorAt(x: 0, y: 0)).alphaComponent, 0, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(bitmap.colorAt(x: 39, y: 39)).alphaComponent, 0, accuracy: 0.01)
        let center = try XCTUnwrap(bitmap.colorAt(x: 20, y: 20)?.usingColorSpace(.deviceRGB))
        let fill = try XCTUnwrap(NSColor.windowBackgroundColor.usingColorSpace(.deviceRGB))
        XCTAssertEqual(center.alphaComponent, 1, accuracy: 0.01)
        XCTAssertEqual(center.redComponent, fill.redComponent, accuracy: 0.01)
        XCTAssertEqual(center.greenComponent, fill.greenComponent, accuracy: 0.01)
        XCTAssertEqual(center.blueComponent, fill.blueComponent, accuracy: 0.01)
    }

    func testZeroCornerRadiusFillsPreviouslyTransparentCorners() throws {
        let view = SuggestionsWindowContentView(
            frame: NSRect(x: 0, y: 0, width: 40, height: 40)
        )
        view.cornerRadius = 0

        let bitmap = try renderBackground(of: view)

        XCTAssertEqual(try XCTUnwrap(bitmap.colorAt(x: 0, y: 0)).alphaComponent, 1, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(bitmap.colorAt(x: 39, y: 39)).alphaComponent, 1, accuracy: 0.01)
    }

    func testAccessibilitySelectionHandlesMissingAndUnrelatedChildren() {
        let contentView = CustomAccessibilityChildrenContentView()
        XCTAssertEqual(contentView.accessibilitySelectedChildren()?.count, 0)

        let selectedRow = SuggestionView()
        selectedRow.highlighted = true
        contentView.reportedChildren = [NSView(), selectedRow]

        XCTAssertEqual(contentView.accessibilitySelectedChildren() as? [SuggestionView], [selectedRow])
    }

    private func renderBackground(of view: SuggestionsWindowContentView) throws -> NSBitmapImageRep {
        let bitmap = try XCTUnwrap(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 40, pixelsHigh: 40, bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0
        ))
        let context = try XCTUnwrap(NSGraphicsContext(bitmapImageRep: bitmap))
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = context
        NSColor.clear.setFill()
        view.bounds.fill(using: .copy)
        view.draw(view.bounds)
        context.flushGraphics()
        return bitmap
    }
}

private final class CustomAccessibilityChildrenContentView: SuggestionsWindowContentView {
    var reportedChildren: [Any]?

    override func accessibilityChildren() -> [Any]? {
        reportedChildren
    }
}
