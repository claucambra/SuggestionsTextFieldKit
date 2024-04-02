//
//  SuggestionViewController.swift
//
//
//  Created by Claudio Cambra on 2/4/24.
//

import AppKit
import Foundation

class SuggestionViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = SuggestionView()
    }

    override var representedObject: Any? {
        didSet {
            guard let representedObject = representedObject as? Suggestion,
                  let view = view as? SuggestionView
            else { return }

            view.label.stringValue = representedObject.displayText
            view.imageView.image = NSImage(named: representedObject.imageName)
        }
    }
}
