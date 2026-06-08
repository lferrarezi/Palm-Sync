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
        .executableTarget(
            name: "PalmSyncMac"
        ),
        .executableTarget(
            name: "PalmProbe"
        )
    ]
)

