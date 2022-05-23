// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Hyperspace",
    platforms: [
        .macOS(.v11),
        .macCatalyst(.v13),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "Hyperspace", targets: ["Hyperspace"])
    ],
    targets: [
        .target(name: "Hyperspace", path: "Sources"),
        .testTarget(name: "HyperspaceTests", dependencies: ["Hyperspace"], path: "Tests")
    ]
)
