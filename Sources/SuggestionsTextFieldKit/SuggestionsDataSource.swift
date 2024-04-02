//
//  SuggestionsDataSource.swift
//
//
//  Created by Claudio Cambra on 2/4/24.
//

import AppKit
import Foundation

public protocol SuggestionsDataSource {
    var inputString: String { get set }
    var suggestions: [Suggestion] { get }
}
