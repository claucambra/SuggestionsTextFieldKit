//
//  SuggestionsTextFieldDelegate.swift
//
//
//  Created by Claudio Cambra on 2/4/24.
//

import AppKit
import Foundation

public class SuggestionsTextFieldDelegate: NSObject, NSTextFieldDelegate {
    public var suggestionsWindowController: SuggestionsWindowController?

    public func controlTextDidBeginEditing(_ notification: Notification) {
        guard let control = notification.object as? NSControl else { return }
        suggestionsWindowController?.dataSource?.inputString = control.stringValue
        if !control.stringValue.isEmpty, suggestionsWindowController?.window?.isVisible == false {
            suggestionsWindowController?.showWindow(self)
        }
    }

    public func controlTextDidChange(_ notification: Notification) {
        guard let control = notification.object as? NSControl else { return }
        suggestionsWindowController?.dataSource?.inputString = control.stringValue
        if suggestionsWindowController?.window?.isVisible == false {
            suggestionsWindowController?.showWindow(self)
        }
    }
}
