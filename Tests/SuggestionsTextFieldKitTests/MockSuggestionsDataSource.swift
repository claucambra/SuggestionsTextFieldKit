//
//  MockSuggestionsDataSource.swift
//
//
//  Created by Claudio Cambra on 9/4/24.
//

import Foundation
import SuggestionsTextFieldKit

class MockSuggestionsDataSource: NSObject, SuggestionsDataSource {
    var inputString = ""
    var suggestions: [SuggestionsTextFieldKit.Suggestion] = []
}
