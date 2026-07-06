//
//  Bundle+DeviceNameKit.swift
//  MIT License (c) 2025 Daehee Kim
//

import Foundation

extension Bundle {
    /// The bundle containing the packaged device name data.
    ///
    /// Resolves to `Bundle.module` for Swift Package Manager builds and to the
    /// `DeviceNameKit` resource bundle for CocoaPods builds.
    static var deviceNameKitResources: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        let container = Bundle(for: DeviceNameFetcher.self)
        if let url = container.url(forResource: "DeviceNameKit", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return container
        #endif
    }
}
