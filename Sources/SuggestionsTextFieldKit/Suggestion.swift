//
//  File.swift
//  
//
//  Created by Claudio Cambra on 2/4/24.
//

import Foundation

public struct Suggestion {
    public let imageName: String
    public let displayText: String
    public let data: Any

    public init(imageName: String, displayText: String, data: Any) {
        self.imageName = imageName
        self.displayText = displayText
        self.data = data
    }
}
