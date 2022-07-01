// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Dockable",
    platforms: [
        // Minimum OS version is currently limited by the ImageRenderer:
        //      https://developer.apple.com/documentation/swiftui/imagerenderer
        // A GitHub issue is open to explore backporting to older versions:
        //      https://github.com/getsidetrack/swiftui-dockable/issues/4
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .macCatalyst(.v16),
    ],
    products: [
        .library(name: "Dockable", targets: ["Dockable"]),
    ],
    targets: [
        .target(name: "Dockable"),
    ]
)
