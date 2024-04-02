//
//  SuggestionView.swift
//  
//
//  Created by Claudio Cambra on 2/4/24.
//

import AppKit
import Foundation

class SuggestionView: NSView {
    let highlightSideMargin: CGFloat = 6.0
    let sideMargin: CGFloat = 8.0
    let imageSize: CGFloat = 16.0
    let spaceBetweenLabelAndImage: CGFloat = 6.0

    var imageView: NSImageView!
    var backgroundView: NSVisualEffectView!
    var label: NSTextField!

    var highlighted: Bool = false {
        didSet {
            backgroundView.material = highlighted ? .selection : .menu
            backgroundView.isEmphasized = highlighted
            backgroundView.state = highlighted ? .active : .inactive
            label.cell?.backgroundStyle = highlighted ? .emphasized : .normal
            imageView.cell?.backgroundStyle = highlighted ? .emphasized : .normal
        }
    }

    init() {
        super.init(frame: .zero)

        backgroundView = NSVisualEffectView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(backgroundView)
        addConstraints([
            backgroundView.leadingAnchor.constraint(
                equalTo: leadingAnchor, constant: highlightSideMargin
            ),
            backgroundView.trailingAnchor.constraint(
                equalTo: trailingAnchor, constant: 0.0 - highlightSideMargin
            ),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(imageView)
        backgroundView.addConstraints([
            imageView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: sideMargin),
            imageView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: imageSize),
            imageView.heightAnchor.constraint(equalToConstant: imageSize),
        ])

        if #available(macOS 10.14, *) {
            imageView.contentTintColor = NSColor.labelColor
        }

        label = NSTextField(labelWithString: "")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingTail
        backgroundView.addSubview(label)
        backgroundView.addConstraints([
            label.leadingAnchor.constraint(
                equalTo: imageView.trailingAnchor, constant: spaceBetweenLabelAndImage
            ),
            label.trailingAnchor.constraint(
                equalTo: backgroundView.trailingAnchor, constant: 0.0 - sideMargin
            ),
            label.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func accessibilityChildren() -> [Any]? { [] }
    override func accessibilityLabel() -> String? { label.stringValue }
}
