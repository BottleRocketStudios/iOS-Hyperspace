// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Hyperspace",
    platforms: [
        .macOS(.v10_15),
        .macCatalyst(.v13),
        .iOS(.v12),
        .tvOS(.v12),
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
