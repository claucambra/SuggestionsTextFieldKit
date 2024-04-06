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

        suggestionsWindowController?.dataSource?.inputString = control.stringValue

        if !control.stringValue.isEmpty, suggestionsWindowController?.window?.isVisible == false {
            suggestionsWindowController?.showWindow(self)
        }
    }

    public func controlTextDidChange(_ notification: Notification) {
        guard let control = notification.object as? NSControl else { return }
        suggestionsWindowController?.dataSource?.inputString = control.stringValue

        if control.stringValue.isEmpty, suggestionsWindowController?.window?.isVisible == true {
            suggestionsWindowController?.close()
        } else if suggestionsWindowController?.window?.isVisible == false {
            suggestionsWindowController?.showWindow(self)
        }
    }

    public func controlTextDidEndEditing(_ notification: Notification) {
        if suggestionsWindowController?.window?.isVisible == true {
            suggestionsWindowController?.close()
        }
    }
}
