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
        didSet {
            suggestionsWindowController?.parentTextField = targetTextField
            targetTextField?.delegate = self
            targetTextField?.target = self
            targetTextField?.action = #selector(acceptSuggestion(sender:))
        }
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
            suggestionsWindowController?.enableSuggestions()
        }
    }

    public func controlTextDidChange(_ notification: Notification) {
        guard let control = notification.object as? NSControl else { return }

        if suggestionsWindowController == nil {
            suggestionsWindowController = SuggestionsWindowController()
        }

        suggestionsDataSource?.inputString = control.stringValue

        if control.stringValue.isEmpty {
            suggestionsWindowController?.cancelSuggestions()
        } else {
            suggestionsWindowController?.enableSuggestions()
        }
    }

    public func controlTextDidEndEditing(_ notification: Notification) {
        suggestionsWindowController?.cancelSuggestions()
    }

    public func control(
        _ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector
    ) -> Bool {
        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            // Move up in the suggested selections list
            suggestionsWindowController?.moveUp(textView)
            return true
        }

        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            // Move down in the suggested selections list
            suggestionsWindowController?.moveDown(textView)
            return true
        }

        // This is "autocomplete" functionality, invoked when the user presses option-escaped.
        // By overriding this command we prevent AppKit's auto completion and can respond to
        // the user's intention by showing or cancelling our custom suggestions window.
        if commandSelector == #selector(NSResponder.complete(_:)) {
            if suggestionsWindowController?.window?.isVisible == true {
                suggestionsWindowController?.cancelSuggestions()
            } else {
                suggestionsWindowController?.enableSuggestions()
            }
            return true
        }
        // This is a command that we don't specifically handle, let the field editor do the 
        // appropriate thing.
        return false
    }

    @objc public func acceptSuggestion(sender: Any) {
        guard let suggestionsWindowController = suggestionsWindowController else { return }
        confirmationHandler?(suggestionsWindowController.selectedSuggestion)
    }
}
