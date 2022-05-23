// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "Hyperspace",
    platforms: [
        .macOS(.v11),
        .macCatalyst(.v15),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "Hyperspace", targets: ["Hyperspace"])
    ],
    targets: [
        .target(name: "Hyperspace", path: "Sources"),
        .testTarget(name: "HyperspaceTests", dependencies: ["Hyperspace"], path: "Tests")
    ]
)
