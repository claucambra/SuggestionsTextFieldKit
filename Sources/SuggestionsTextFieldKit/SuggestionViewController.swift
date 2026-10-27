//
//  SuggestionViewController.swift
//
//
//  Created by Claudio Cambra on 2/4/24.
//

import AppKit
import Foundation

class SuggestionViewController: NSViewController {
    var suggestionView: SuggestionView? { view as? SuggestionView }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        // Suggestion controllers are constructed programmatically, not decoded from archives.
        return nil
    }

    override func loadView() {
        self.view = SuggestionView()
    }

    override var representedObject: Any? {
        didSet {
            guard let representedObject = representedObject as? Suggestion,
                  let view = suggestionView
            else { return }

            view.label.stringValue = representedObject.displayText
            view.imageView.image = NSImage(named: representedObject.imageName)
        }
    }
}
