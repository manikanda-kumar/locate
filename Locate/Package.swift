// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Locate",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "LocateCore", targets: ["LocateCore"]),
        .executable(name: "Locate", targets: ["Locate"])
    ],
    targets: [
        .target(
            name: "LocateCore",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "Locate",
            dependencies: ["LocateCore"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "LocateCoreTests",
            dependencies: ["LocateCore"]
        ),
    ]
)