//
//  SuggestionsDataSource.swift
//
//
//  Created by Claudio Cambra on 2/4/24.
//

import AppKit
import Foundation

public let SuggestionsChangedNotificationName = NSNotification.Name("SuggestionsChanged")

public protocol SuggestionsDataSource {
    var inputString: String { get set }
    var suggestions: [Suggestion] { get }
}
