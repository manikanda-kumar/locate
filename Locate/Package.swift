// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Locate",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "LocateCore", targets: ["LocateCore"]),
        .library(name: "LocateViewModel", targets: ["LocateViewModel"]),
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
        .target(
            name: "LocateViewModel",
            dependencies: ["LocateCore"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "Locate",
            dependencies: ["LocateCore", "LocateViewModel"],
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
        // LocateUITests: Run only in Xcode 26, not from 'swift test'
        // To enable: Uncomment the target below and run tests in Xcode
        // .testTarget(
        //     name: "LocateUITests",
        //     dependencies: ["Locate"]
        // ),
    ]
)
