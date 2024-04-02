//
//  SuggestionsTextFieldDelegate.swift
//
//
//  Created by Claudio Cambra on 2/4/24.
//

import AppKit
import Foundation

class SuggestionsTextFieldDelegate: NSObject, NSTextFieldDelegate {
    var suggestionsWindowController: SuggestionsWindowController?

    func controlTextDidBeginEditing(_ notification: Notification) {
        guard let control = notification.object as? NSControl else { return }
        suggestionsWindowController?.dataSource?.inputString = control.stringValue
    }

    func controlTextDidChange(_ notification: Notification) {
        guard let control = notification.object as? NSControl else { return }
        suggestionsWindowController?.dataSource?.inputString = control.stringValue
    }
}
