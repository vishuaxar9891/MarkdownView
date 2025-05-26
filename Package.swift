// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MarkdownView",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13),
    ],
    products: [
        .library(name: "MarkdownView", targets: ["MarkdownView"]),
        .library(name: "MarkdownParser", targets: ["MarkdownParser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections", from: "1.2.0"),
        .package(url: "https://github.com/mgriebling/SwiftMath", from: "1.7.1"),
        .package(url: "https://github.com/Lakr233/Splash", from: "0.17.0"),
        .package(url: "https://github.com/Lakr233/Litext", from: "0.4.1"),
        .package(url: "https://github.com/Lakr233/swift-cmark", from: "0.6.1"),
        .package(url: "https://github.com/nicklockwood/LRUCache", from: "1.0.7"),
    ],
    targets: [
        .target(name: "MarkdownView", dependencies: [
            "Litext",
            "Splash",
            "MarkdownParser",
            "SwiftMath",
            "LRUCache",
            .product(name: "DequeModule", package: "swift-collections"),
        ]),
        .target(name: "MarkdownParser", dependencies: [
            .product(name: "cmark-gfm", package: "swift-cmark"),
            .product(name: "cmark-gfm-extensions", package: "swift-cmark"),
        ]),
    ]
)
