// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VolumeSync",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VolumeSync", targets: ["VolumeSync"])
    ],
    targets: [
        .executableTarget(
            name: "VolumeSync",
            path: "Sources/VolumeSync"
        )
    ]
)
