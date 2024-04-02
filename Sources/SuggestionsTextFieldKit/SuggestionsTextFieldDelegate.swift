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
    }

    public func controlTextDidChange(_ notification: Notification) {
        guard let control = notification.object as? NSControl else { return }
        suggestionsWindowController?.dataSource?.inputString = control.stringValue
    }
}
