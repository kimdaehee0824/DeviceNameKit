//
//  Constant.swift
//  MIT License (c) 2025 Daehee Kim
//

import Foundation

/// A structure that defines constant values used in the application.
struct Constant {

    /// The base URL path for fetching the device model name list.
    ///
    /// - Note: If you fork this repository, make sure to change `kimdaehee0824`
    ///   to your own repository name.
    static let modelNamePath: String = "https://raw.githubusercontent.com/kimdaehee0824/DeviceNameKit/main/DeviceName/"

    /// The UserDefaults key used to store the cached device name.
    static let userDefaultsDeviceNameKey = "device_name_cache"

    /// The UserDefaults key used to store the last fetch timestamp.
    static let userDefaultsLastFetchKey = "device_name_last_fetch"
}
