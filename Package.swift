// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "Pipify",
    platforms: [
        // Minimum OS version is currently limited by the ImageRenderer:
        //      https://developer.apple.com/documentation/swiftui/imagerenderer
        // A GitHub issue is open to explore backporting to older versions:
        //      https://github.com/getsidetrack/swiftui-pipify/issues/4
        
        // We use string initialisers for versions in order to reduce the swift tools version required
        // (5.6 instead of 5.7). This is for SwiftPackageIndex.
        .iOS("16.0.0"),
        .macOS("13.0.0"),
        .tvOS("16.0.0"),
        .macCatalyst("16.0.0"),
    ],
    products: [
        .library(name: "Pipify", targets: ["Pipify"]),
    ],
    targets: [
        .target(name: "Pipify", path: "Sources"),
    ]
)
