//
//  SuggestionsDataSource.swift
//
//
//  Created by Claudio Cambra on 2/4/24.
//

import AppKit
import Foundation

protocol SuggestionsDataSource: NSTableViewDataSource {
    var inputString: String { get set }
}
