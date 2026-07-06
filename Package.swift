// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DeviceNameKit",
    platforms: [
        .iOS(.v13),
        .macOS(.v11),
        .watchOS(.v6),
        .tvOS(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "DeviceNameKit",
            targets: ["DeviceNameKit"]),
    ],
    targets: [
        // The target is rooted at the repository so it can bundle the canonical
        // `DeviceName/` folder directly — the same folder served raw to 1.x
        // clients — without keeping a duplicated copy inside `Sources/`.
        .target(
            name: "DeviceNameKit",
            path: ".",
            exclude: [
                "Sources/DeviceNameKitTests",
                "Asset",
                "DeviceNameKit.podspec",
                "LICENSE",
                "README.md",
                "README_ko.md",
                "README_jp.md"
            ],
            sources: ["Sources/DeviceNameKit"],
            resources: [
                .copy("DeviceName")
            ]),
        .testTarget(
            name: "DeviceNameKitTests",
            dependencies: ["DeviceNameKit"],
            path: "Sources/DeviceNameKitTests"
        ),
    ]
)
