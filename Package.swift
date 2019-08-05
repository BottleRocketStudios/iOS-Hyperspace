// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "Hyperspace",
    platforms: [
        .macOS("10.12"),
        .iOS("8.0"),
        .tvOS("9.0"),
        .watchOS("4.2")
    ],
    products: [
        .library(
            name: "Hyperspace",
            targets: ["Hyperspace"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Thomvis/BrightFutures.git", from: "8.0.1")
    ],
    targets: [
        .target(
            name: "Hyperspace",
            dependencies: ["BrightFutures"],
            path: "Sources"),
        .testTarget(
            name: "HyperspaceTests",
            dependencies: ["Hyperspace"],
            path: "Tests")
    ]
)
