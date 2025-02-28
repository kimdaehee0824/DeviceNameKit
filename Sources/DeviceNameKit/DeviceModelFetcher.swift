import Foundation

/// A utility that fetches and stores device model data.
///
/// `DeviceModelFetcher` retrieves device model data from a `DeviceModelProvider`
/// and provides the human-readable model name for the current device.
struct DeviceModelFetcher {
    /// The provider that supplies the device model data.
    private let provider: DeviceModelProvider

    /// A dictionary mapping device identifiers to their human-readable model names.
    private var deviceData: [String: String] = [:]

    /// Initializes a new instance of `DeviceModelFetcher`.
    ///
    /// - Parameter provider: The `DeviceModelProvider` responsible for fetching model data.
    init(provider: DeviceModelProvider) {
        self.provider = provider
    }

    /// Loads the device model mappings from a JSON source.
    ///
    /// This method fetches a dictionary of device identifiers mapped to human-readable model names.
    /// The fetched data is stored in memory for use in `getDeviceModelName()`.
    ///
    /// - Throws: An error if the data cannot be retrieved or parsed.
    mutating func loadDeviceModels() async throws {
        self.deviceData = try await provider.fetchDeviceModels()
    }

    /// Returns the human-readable device model name.
    ///
    /// This method checks the loaded device data to find the corresponding model name for the current device identifier.
    /// If no matching model name is found, it returns the raw device identifier instead.
    ///
    /// - Returns: The human-readable model name if available; otherwise, the raw device identifier.
    func getDeviceModelName() -> String {
        let identifier = provider.getDeviceIdentifier()
        return deviceData[identifier] ?? identifier
    }
}
