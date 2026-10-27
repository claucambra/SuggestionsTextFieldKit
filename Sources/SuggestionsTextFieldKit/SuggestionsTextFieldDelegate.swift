//
//  SuggestionsTextFieldDelegate.swift
//
//
//  Created by Claudio Cambra on 2/4/24.
//

import AppKit
import Foundation

public class SuggestionsTextFieldDelegate: NSObject, NSTextFieldDelegate {
    // The controller also confirms mouse acceptance after delivering the text field action.
    var isHandlingMouseConfirmation = false

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
            guard oldValue !== targetTextField else { return }
            if let oldValue {
                if oldValue.delegate === self {
                    oldValue.delegate = nil
                }
                if oldValue.target === self,
                   oldValue.action == #selector(acceptSuggestion(sender:))
                {
                    oldValue.target = nil
                    oldValue.action = nil
                }
            }
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
        guard let control = notification.object as? NSControl,
              let fieldEditor = control.currentEditor()
        else { return }
        // Reading the control's stringValue validates and commits the current edit.
        let inputString = fieldEditor.string

        if suggestionsWindowController == nil {
            suggestionsWindowController = SuggestionsWindowController()
        }

        suggestionsDataSource?.inputString = inputString

        if !inputString.isEmpty {
            suggestionsWindowController?.enableSuggestions()
        }
    }

    public func controlTextDidChange(_ notification: Notification) {
        guard let control = notification.object as? NSControl,
              let fieldEditor = control.currentEditor()
        else { return }
        let inputString = fieldEditor.string

        if suggestionsWindowController == nil {
            suggestionsWindowController = SuggestionsWindowController()
        }

        suggestionsDataSource?.inputString = inputString

        if inputString.isEmpty {
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
        guard let suggestionsWindowController = suggestionsWindowController,
              !isHandlingMouseConfirmation
        else { return }
        confirmationHandler?(suggestionsWindowController.selectedSuggestion)
    }
}
