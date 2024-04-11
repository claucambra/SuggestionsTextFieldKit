SuggestionsTextFieldKit
=======================

`SuggestionsTextFieldKit` is a library that enables the addition of suggestion functionality to `NSTextField` components within AppKit applications. 

Features
--------

*   **Seamless Integration**: Easily attach to any `NSTextField` to start offering suggestions.
*   **Customizable**: Tailor the suggestions window and data source to fit the needs of your app.
*   **User Interaction**: Handles user selections and confirmations with customizable handlers.
*   **Keyboard Navigation**: Supports moving up and down the suggestions list using keyboard commands.

Installation
------------

### Swift Package Manager

To integrate `SuggestionsTextFieldKit` into your Xcode project, use Swift Package Manager.

Usage
-----

After importing `SuggestionsTextFieldKit`, you can easily add suggestions to an `NSTextField` by setting up a `SuggestionsTextFieldDelegate` and providing a data source for your suggestions.

```swift
import SuggestionsTextFieldKit
import AppKit

class YourViewController: NSViewController {
    @IBOutlet var textField: NSTextField!
    private var suggestionsDelegate: SuggestionsTextFieldDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSuggestions()
    }

    private func setupSuggestions() {
        let suggestionsDelegate = SuggestionsTextFieldDelegate()
        suggestionsDelegate.suggestionsDataSource = self // Ensure your class conforms to `SuggestionsDataSource`
        suggestionsDelegate.selectionHandler = { suggestion in
            print("User selected suggestion: \(suggestion)")
        }
        suggestionsDelegate.confirmationHandler = { suggestion in
            print("User confirmed suggestion: \(suggestion)")
        }
        suggestionsDelegate.targetTextField = textField
        self.suggestionsDelegate = suggestionsDelegate
    }
}

extension YourViewController: SuggestionsDataSource {
    // Implement `SuggestionsDataSource` to provide suggestion data
    var suggestions: [Suggestion] = [] {
        didSet { NotificationCenter.default.post(name: SuggestionsChangedNotificationName, object: self) }
    }
    var inputString: String = "" {
        didSet { Task { await updateSuggestions() } }
    }
    // Implement updateSuggestions()
}

```

Contributing
------------

Contributions to `SuggestionsTextFieldKit` are welcome! Whether you're fixing bugs, adding new features, or improving documentation, please feel free to submit a pull request or open an issue.


License
-------

`SuggestionsTextFieldKit` is available under the LGPL V3 license. See the LICENSE file for more info.
