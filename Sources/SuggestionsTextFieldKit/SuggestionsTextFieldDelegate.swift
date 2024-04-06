//
//  SuggestionsTextFieldDelegate.swift
//
//
//  Created by Claudio Cambra on 2/4/24.
//

import AppKit
import Foundation

public class SuggestionsTextFieldDelegate: NSObject, NSTextFieldDelegate {
    public var suggestionsWindowController: SuggestionsWindowController? {
        didSet {
            suggestionsWindowController?.parentTextField = targetTextField
            suggestionsWindowController?.dataSource = suggestionsDataSource
            suggestionsWindowController?.selectionHandler = selectionHandler
            suggestionsWindowController?.confirmationHandler = confirmationHandler
        }
    }
    public var suggestionsDataSource: SuggestionsDataSource? {
        didSet { suggestionsWindowController?.dataSource = suggestionsDataSource }
    }
    public var targetTextField: NSTextField? {
        didSet { suggestionsWindowController?.parentTextField = targetTextField }
    }
    public var selectionHandler: (@Sendable (Suggestion?) -> ())? {
        didSet { suggestionsWindowController?.selectionHandler = selectionHandler }
    }
    public var confirmationHandler: (@Sendable (Suggestion?) -> ())? {
        didSet { suggestionsWindowController?.confirmationHandler = confirmationHandler }
    }

    public func controlTextDidBeginEditing(_ notification: Notification) {
        guard let control = notification.object as? NSControl else { return }

        if suggestionsWindowController == nil {
            suggestionsWindowController = SuggestionsWindowController()
        }

        suggestionsDataSource?.inputString = control.stringValue

        if !control.stringValue.isEmpty {
            suggestionsWindowController?.repositionWindow()
            suggestionsWindowController?.window?.setIsVisible(true)
            suggestionsWindowController?.window?.orderFront(self)
        }
    }

    public func controlTextDidChange(_ notification: Notification) {
        guard let control = notification.object as? NSControl else { return }

        if suggestionsWindowController == nil {
            suggestionsWindowController = SuggestionsWindowController()
        }

        suggestionsDataSource?.inputString = control.stringValue

        if control.stringValue.isEmpty {
            suggestionsWindowController?.window?.orderOut(self)
        } else {
            suggestionsWindowController?.repositionWindow()
            suggestionsWindowController?.window?.setIsVisible(true)
            suggestionsWindowController?.window?.orderFront(self)
        }
    }

    public func controlTextDidEndEditing(_ notification: Notification) {
        suggestionsWindowController?.window?.orderOut(self)
    }
}
