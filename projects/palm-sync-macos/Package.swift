// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PalmSyncMac",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "PalmSyncMac", targets: ["PalmSyncMac"]),
        .executable(name: "palm-probe", targets: ["PalmProbe"])
    ],
    targets: [
        .target(
            name: "PalmSyncCore"
        ),
        .executableTarget(
            name: "PalmSyncMac",
            dependencies: ["PalmSyncCore"]
        ),
        .executableTarget(
            name: "PalmProbe",
            dependencies: ["PalmSyncCore"]
        ),
        .testTarget(
            name: "PalmSyncMacTests",
            dependencies: ["PalmSyncMac"]
        ),
        .testTarget(
            name: "PalmSyncCoreTests",
            dependencies: ["PalmSyncCore"]
        )
    ]
)

