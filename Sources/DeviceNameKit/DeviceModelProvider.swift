//
//  DeviceModelProvider.swift
//  MIT License (c) 2025 Daehee Kim
//

import Foundation

/// A protocol that provides device model information.
///
/// `DeviceModelProvider` defines methods for retrieving a device's unique identifier
/// and fetching a mapping of model identifiers to their human-readable names.
protocol DeviceModelProvider {
    /// The URL pointing to the JSON file containing device model mappings.
    var jsonURL: URL { get }

    /// Fetches a dictionary mapping device identifiers to their human-readable names.
    ///
    /// - Returns: A dictionary where keys are device identifiers (e.g., `"iPhone17,4"`)
    ///            and values are human-readable names (e.g., `"iPhone 15 Pro"`).
    /// - Throws: An error if the network request fails or the JSON data is invalid.
    func fetchDeviceModels() async throws -> [String: String]

    /// Returns the device's unique identifier.
    ///
    /// - Returns: A string representing the device's internal identifier
    ///            (e.g., `"iPhone17,4"` for iPhone 15 Pro).
    func getDeviceIdentifier() -> String
}

/// Default implementation of `fetchDeviceModels()` for `DeviceModelProvider`.
extension DeviceModelProvider {
    /// Fetches device model mappings from the provided `jsonURL`.
    ///
    /// - Returns: A dictionary mapping device identifiers to their human-readable names.
    /// - Throws: An error if the network request fails or JSON parsing is unsuccessful.
    func fetchDeviceModels() async throws -> [String: String] {
        let (data, _) = try await URLSession.shared.data(from: jsonURL)
        return try JSONDecoder().decode([String: String].self, from: data)
    }

    /// Converts a `utsname` structure into a string representing the device identifier.
    ///
    /// - Parameter machine: A reference to the `utsname` structure.
    /// - Returns: A string representation of the machine identifier (e.g., `"iPhone17,4"`).
    func convertMachineToString(_ machine: inout utsname) -> String {
        return withUnsafeBytes(of: &machine.machine) { rawBufferPointer in
            let pointer = rawBufferPointer.bindMemory(to: CChar.self).baseAddress!
            return String(cString: pointer)
        }
    }
}

/// Provides device model information for iOS devices (iPhone & iPad).
struct iOSDeviceModelProvider: DeviceModelProvider {
    let jsonURL = URL(string: "\(Constant.modelNamePath)iOS.json")!

    /// Returns the unique device identifier for iOS devices.
    func getDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return convertMachineToString(&systemInfo)
    }
}

/// Provides device model information for watchOS devices (Apple Watch).
struct watchOSDeviceModelProvider: DeviceModelProvider {
    let jsonURL = URL(string: "\(Constant.modelNamePath)watchOS.json")!

    /// Returns the unique device identifier for watchOS devices.
    func getDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return convertMachineToString(&systemInfo)
    }
}

/// Provides device model information for macOS devices (Mac).
struct macOSDeviceModelProvider: DeviceModelProvider {
    let jsonURL = URL(string: "\(Constant.modelNamePath)macOS.json")!

    /// Returns the unique device identifier for macOS devices.
    func getDeviceIdentifier() -> String {
        var size: Int = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
    }
}

/// Provides device model information for tvOS devices (Apple TV).
struct tvOSDeviceModelProvider: DeviceModelProvider {
    let jsonURL = URL(string: "\(Constant.modelNamePath)tvOS.json")!

    /// Returns the unique device identifier for tvOS devices.
    func getDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return convertMachineToString(&systemInfo)
    }
}

/// Provides device model information for visionOS devices (Apple Vision Pro).
struct visionOSDeviceModelProvider: DeviceModelProvider {
    let jsonURL = URL(string: "\(Constant.modelNamePath)visionOS.json")!

    /// Returns the unique device identifier for visionOS devices.
    func getDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return convertMachineToString(&systemInfo)
    }
}
