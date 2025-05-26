# MarkdownView

A powerful pure UIKit framework for rendering Markdown documents with real-time parsing and rendering capabilities. Battle tested in [FlowDown](https://github.com/Lakr233/FlowDown).

## Preview

![Preview](./Resources/Simulator%20Screenshot%20-%20iPad%20mini%20(A17%20Pro)%20-%202025-05-27%20at%2003.03.27.png)

## Features

- 🚀 **Real-time Rendering**: Live Markdown parsing and rendering as you type
- 🎨 **Syntax Highlighting**: Beautiful code syntax highlighting with Splash
- 📊 **Math Rendering**: LaTeX math formula rendering with SwiftMath
- 📱 **iOS Optimized**: Native UIKit implementation for optimal performance

## Installation

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Lakr233/MarkdownView", from: "0.1.5"),
]
```

Platform compatibility:
- iOS 13.0+
- Mac Catalyst 13.0+

## Usage

```swift
import MarkdownView
import MarkdownParser

let parser = MarkdownParser()
let document = parser.feed("hi")
markdownTextView.nodes = document
```

## Example

Check out the included example project to see MarkdownView in action:

```bash
cd Example
open Example.xcodeproj
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

### Acknowledgments

This project includes code adapted from [swift-markdown-ui](https://github.com/gonzalezreal/swift-markdown-ui) by Guillermo Gonzalez, used under the MIT License.

---

Copyright 2025 © Lakr Aream. All rights reserved.