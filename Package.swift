// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DeviceNameKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .watchOS(.v5),
        .tvOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "DeviceNameKit",
            targets: ["DeviceNameKit"]),
    ],
    targets: [
        .target(
            name: "DeviceNameKit"),
        .testTarget(
            name: "DeviceNameKitTests",
            dependencies: ["DeviceNameKit"]
        ),
    ]
)
