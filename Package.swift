// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Hyperspace",
    platforms: [
        .macOS("10.15"),
        .iOS("12.0"),
        .tvOS("12.0"),
        .watchOS("6.0")
    ],
    products: [
        .library(
            name: "Hyperspace",
            targets: ["Hyperspace"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Hyperspace",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "HyperspaceTests",
            dependencies: ["Hyperspace"],
            path: "Tests")
    ]
)
