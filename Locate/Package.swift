// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Locate",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "LocateCore", targets: ["LocateCore"]),
        .executable(name: "Locate", targets: ["Locate"]),
        .executable(name: "LocateCLI", targets: ["LocateCLI"])
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
        .executableTarget(
            name: "LocateCLI",
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
