# MarkdownView

A powerful pure UIKit framework for rendering Markdown documents with real-time parsing and rendering capabilities. This library has been battle-tested in [FlowDown](https://github.com/Lakr233/FlowDown). 

[![Latest Release](https://img.shields.io/github/v/release/vishuaxar9891/MarkdownView?color=blue&label=Latest%20Release&style=flat-square)](https://github.com/vishuaxar9891/MarkdownView/releases)

## Preview

![Preview](./Resources/Simulator%20Screenshot%20-%20iPad%20mini%20(A17%20Pro)%20-%202025-05-27%20at%2003.03.27.png)

## Features

- **Real-time Rendering**: Live Markdown parsing and rendering as you type.
- **Syntax Highlighting**: Beautiful code syntax highlighting with Splash.
- **Math Rendering**: LaTeX math formula rendering with SwiftMath.
- **iOS Optimized**: Native UIKit implementation for optimal performance.

## Installation

To install MarkdownView, add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Lakr233/MarkdownView", from: "0.1.5"),
]
```

### Platform Compatibility

- iOS 13.0+
- Mac Catalyst 13.0+

## Usage

To use MarkdownView in your project, import the necessary modules and set up the parser:

```swift
import MarkdownView
import MarkdownParser

let parser = MarkdownParser()
let document = parser.feed("hi")
markdownTextView.nodes = document.nodes
```

### Example

Here is a simple example of how to create a Markdown view:

```swift
import UIKit
import MarkdownView

class ViewController: UIViewController {
    let markdownTextView = MarkdownView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMarkdownView()
    }

    func setupMarkdownView() {
        markdownTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(markdownTextView)

        NSLayoutConstraint.activate([
            markdownTextView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            markdownTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            markdownTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            markdownTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        let markdownText = """
        # Welcome to MarkdownView
        This is a simple example of using MarkdownView.
        """
        markdownTextView.load(markdown: markdownText)
    }
}
```

## Contributing

We welcome contributions to MarkdownView. If you would like to contribute, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes.
4. Write tests for your changes.
5. Submit a pull request.

## Issues

If you encounter any issues or have suggestions, please open an issue in the [Issues section](https://github.com/vishuaxar9891/MarkdownView/issues).

## Documentation

For detailed documentation, please refer to the [Wiki section](https://github.com/vishuaxar9891/MarkdownView/wiki).

## License

MarkdownView is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.

## Releases

To check the latest releases, visit the [Releases section](https://github.com/vishuaxar9891/MarkdownView/releases). You can download the latest version and integrate it into your project.

## Acknowledgments

Thanks to the contributors and the community for supporting MarkdownView. Your feedback and contributions help improve the library.

---

Feel free to reach out if you have any questions or need further assistance. Enjoy using MarkdownView!