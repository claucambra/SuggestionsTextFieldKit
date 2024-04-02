//
//  SuggestionsTextFieldController.swift
//
//
//  Created by Claudio Cambra on 2/4/24.
//

import AppKit
import Foundation

class SuggestionsTextFieldDelegate: NSObject, NSTextFieldDelegate {
    var dataSource: SuggestionsDataSource? = nil

    func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else {
            debugPrint("Notification object was not a textfield!")
            return
        }
        dataSource?.inputString = textField.stringValue
    }
}
