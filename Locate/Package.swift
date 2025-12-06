// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Locate",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "Locate", targets: ["Locate"])
    ],
    targets: [
        .executableTarget(
            name: "Locate",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)
