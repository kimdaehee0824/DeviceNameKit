//
//  DeviceModelProvider.swift
//  MIT License (c) 2025 Daehee Kim
//

import Foundation

/// A protocol that provides device model information.
///
/// `DeviceModelProvider` defines how to read the current device identifier and
/// how to obtain the identifier-to-name mapping, both from the data set bundled
/// with the package and from the remote repository.
protocol DeviceModelProvider: Sendable {
    /// The URL pointing to the remote JSON file containing the latest device model mappings.
    var jsonURL: URL { get }

    /// The bundled JSON file name (without extension) for this platform.
    var bundledFileName: String { get }

    /// Fetches the latest mapping of device identifiers to human-readable names.
    ///
    /// - Returns: A dictionary where keys are device identifiers (e.g., `"iPhone15,2"`)
    ///            and values are human-readable names (e.g., `"iPhone 14 Pro"`).
    /// - Throws: An error if the network request fails or the JSON data is invalid.
    func fetchDeviceModels() async throws -> [String: String]

    /// Loads the mapping shipped inside the package resources.
    ///
    /// - Throws: An error if the bundled resource is missing or cannot be decoded.
    func loadBundledModels() throws -> [String: String]

    /// Returns the device's unique identifier.
    ///
    /// - Returns: A string representing the device's internal identifier
    ///            (e.g., `"iPhone15,2"` for iPhone 14 Pro).
    func getDeviceIdentifier() -> String
}

/// An error thrown when the bundled data set cannot be located.
enum BundledDataError: Error {
    case resourceNotFound(String)
}

extension DeviceModelProvider {
    /// Fetches device model mappings from the remote `jsonURL`.
    func fetchDeviceModels() async throws -> [String: String] {
        let (data, _) = try await URLSession.shared.data(from: jsonURL)
        return try JSONDecoder().decode([String: String].self, from: data)
    }

    /// Loads device model mappings from the JSON file shipped with the package.
    func loadBundledModels() throws -> [String: String] {
        let bundle = Bundle.deviceNameKitResources
        guard let url = bundle.url(forResource: bundledFileName,
                                   withExtension: "json",
                                   subdirectory: Constant.bundledDataDirectory)
                ?? bundle.url(forResource: bundledFileName, withExtension: "json") else {
            throw BundledDataError.resourceNotFound("\(bundledFileName).json")
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([String: String].self, from: data)
    }

    /// Returns the machine identifier reported by `uname`.
    ///
    /// On the simulator, the identifier of the simulated device is returned
    /// instead of the host architecture (e.g., `"iPhone17,1"` rather than `"arm64"`).
    func machineIdentifier() -> String {
        #if targetEnvironment(simulator)
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated
        }
        #endif
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { rawBufferPointer in
            let pointer = rawBufferPointer.bindMemory(to: CChar.self).baseAddress!
            return String(cString: pointer)
        }
    }
}

/// Provides device model information for iOS devices (iPhone & iPad).
struct iOSDeviceModelProvider: DeviceModelProvider {
    let jsonURL = URL(string: "\(Constant.modelNamePath)iOS.json")!
    let bundledFileName = "iOS"

    /// Returns the unique device identifier for iOS devices.
    func getDeviceIdentifier() -> String {
        machineIdentifier()
    }
}

/// Provides device model information for watchOS devices (Apple Watch).
struct watchOSDeviceModelProvider: DeviceModelProvider {
    let jsonURL = URL(string: "\(Constant.modelNamePath)watchOS.json")!
    let bundledFileName = "watchOS"

    /// Returns the unique device identifier for watchOS devices.
    func getDeviceIdentifier() -> String {
        machineIdentifier()
    }
}

/// Provides device model information for macOS devices (Mac).
struct macOSDeviceModelProvider: DeviceModelProvider {
    let jsonURL = URL(string: "\(Constant.modelNamePath)macOS.json")!
    let bundledFileName = "macOS"

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
    let bundledFileName = "tvOS"

    /// Returns the unique device identifier for tvOS devices.
    func getDeviceIdentifier() -> String {
        machineIdentifier()
    }
}

/// Provides device model information for visionOS devices (Apple Vision Pro).
struct visionOSDeviceModelProvider: DeviceModelProvider {
    let jsonURL = URL(string: "\(Constant.modelNamePath)visionOS.json")!
    let bundledFileName = "visionOS"

    /// Returns the unique device identifier for visionOS devices.
    func getDeviceIdentifier() -> String {
        machineIdentifier()
    }
}
