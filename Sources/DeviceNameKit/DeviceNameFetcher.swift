//
//  DeviceNameFetcher.swift
//  MIT License (c) 2025 Daehee Kim
//

import Foundation
import Combine
import OSLog

/// A class responsible for fetching and caching the device model name.
///
/// `DeviceNameFetcher` retrieves the device model name and stores it in `UserDefaults`
/// to optimize repeated queries. It supports multiple fetching methods:
/// - **Async/Await**
/// - **Completion Handler**
/// - **Combine API** (`Future`)
///
/// The cached data is automatically invalidated based on the `DeviceNameCachePolicy`.
public final class DeviceNameFetcher {
    private let fetcher: DeviceModelFetcher
    private let cachePolicy: DeviceNameCachePolicy

    /// Initializes a new instance of `DeviceNameFetcher`.
    ///
    /// - Parameter cachePolicy: Defines the caching policy. The default is `.noCache`.
    public init(cachePolicy: DeviceNameCachePolicy = .noCache) {
        self.cachePolicy = cachePolicy
        let provider: DeviceModelProvider

        #if os(iOS)
        provider = iOSDeviceModelProvider()
        #elseif os(watchOS)
        provider = watchOSDeviceModelProvider()
        #elseif os(macOS)
        provider = macOSDeviceModelProvider()
        #elseif os(tvOS)
        provider = tvOSDeviceModelProvider()
        #elseif os(visionOS)
        provider = visionOSDeviceModelProvider()
        #else
        fatalError("Unsupported OS")
        #endif

        self.fetcher = DeviceModelFetcher(provider: provider)
    }

    /// Preloads the device model name into the cache.
    ///
    /// This method fetches and stores the device model name if caching is enabled.
    /// If an error occurs, it logs the failure but does not interrupt execution.
    ///
    /// - Returns: The current `DeviceNameFetcher` instance for method chaining.
    @discardableResult
    public func preload() -> Self {
        guard cachePolicy != .noCache else { return self }

        if let cachedName = Self.getCachedDeviceName(), isValidCache() {
            os_log("Using cached device model: %@", log: .default, type: .info, cachedName)
            return self
        }

        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            do {
                let name = try await self.getDeviceName()
                Self.cacheDeviceName(name)
                os_log("Device model cached: %@", log: .default, type: .info, name)
            } catch {
                os_log("DeviceNameFetcher Preload Error: %@", log: .default, type: .error, error.localizedDescription)
            }
        }

        return self
    }

    /// Retrieves the device model name asynchronously.
    ///
    /// - Returns: A `String` representing the device model name.
    /// - Throws: A `DeviceNameFetcherError.fetchFailed` error if the fetch operation fails.
    public func getDeviceName() async throws -> String {
        if let cachedName = Self.getCachedDeviceName(), isValidCache() { return cachedName }

        var fetcher = self.fetcher
        let deviceIdentifier = fetcher.getDeviceModelName()

        do {
            try await fetcher.loadDeviceModels()
            let modelName = fetcher.getDeviceModelName()

            if cachePolicy != .noCache {
                Self.cacheDeviceName(modelName)
            }
            return modelName
        } catch {
            throw DeviceNameFetcherError.fetchFailed(deviceIdentifier: deviceIdentifier, underlyingError: error)
        }
    }

    /// Retrieves the device model name asynchronously with internal error handling.
    ///
    /// If fetching fails, it returns the original device identifier instead of throwing an error.
    /// The failure is logged for debugging purposes.
    ///
    /// - Returns: A `String` representing the device model name, or the original device identifier in case of failure.
    public func getSafeDeviceName() async -> String {
        if let cachedName = Self.getCachedDeviceName(), isValidCache() { return cachedName }

        var fetcher = self.fetcher
        let deviceIdentifier = fetcher.getDeviceModelName()

        do {
            try await fetcher.loadDeviceModels()
            let modelName = fetcher.getDeviceModelName()

            if cachePolicy != .noCache { Self.cacheDeviceName(modelName) }
            return modelName
        } catch {
            os_log("Failed to fetch device model name: %@ (Identifier: %@)", log: .default, type: .error, error.localizedDescription, deviceIdentifier)
            return deviceIdentifier
        }
    }

    /// Retrieves the device model name using a completion handler.
    ///
    /// - Parameter completion: A closure that returns the device model name or an error.
    /// - Note: If an error occurs, `DeviceNameFetcherError.fetchFailed` is returned.
    public func getDeviceName(completion: @escaping (Result<String, DeviceNameFetcherError>) -> Void) {
        if let cachedName = Self.getCachedDeviceName(), isValidCache() {
            completion(.success(cachedName))
            return
        }

        let deviceIdentifier = fetcher.getDeviceModelName()

        Task {
            do {
                let name = try await getDeviceName()
                completion(.success(name))
            } catch {
                completion(.failure(DeviceNameFetcherError.fetchFailed(deviceIdentifier: deviceIdentifier, underlyingError: error)))
            }
        }
    }

    /// Retrieves the device model name using Combine API.
    ///
    /// - Returns: A `Future` publisher that emits the device model name or an error.
    /// - Note: If an error occurs, `DeviceNameFetcherError.fetchFailed` is returned.
    public func getDeviceNamePublisher() -> AnyPublisher<String, DeviceNameFetcherError> {
        if let cachedName = Self.getCachedDeviceName(), isValidCache() {
            return Just(cachedName)
                .setFailureType(to: DeviceNameFetcherError.self)
                .eraseToAnyPublisher()
        }

        let deviceIdentifier = fetcher.getDeviceModelName()

        return Future { promise in
            Task {
                do {
                    let name = try await self.getDeviceName()
                    promise(.success(name))
                } catch {
                    let customError = DeviceNameFetcherError.fetchFailed(deviceIdentifier: deviceIdentifier, underlyingError: error)
                    promise(.failure(customError))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// Provides direct access to the cached device model name.
    public var deviceModel: String? {
        return Self.getCachedDeviceName()
    }

    // MARK: - Private Caching Logic

    /// Retrieves the cached device model name from `UserDefaults`.
    ///
    /// - Returns: A cached device model name if available, otherwise `nil`.
    private static func getCachedDeviceName() -> String? {
        return UserDefaults.standard.string(forKey: Constant.userDefaultsDeviceNameKey)
    }

    /// Saves the device model name to `UserDefaults`.
    ///
    /// - Parameter name: The device model name to be cached.
    private static func cacheDeviceName(_ name: String) {
        UserDefaults.standard.setValue(name, forKey: Constant.userDefaultsDeviceNameKey)
        UserDefaults.standard.setValue(Date().timeIntervalSince1970, forKey: Constant.userDefaultsLastFetchKey)
    }

    /// Validates if the cached data is still valid based on the caching policy.
    ///
    /// - Returns: `true` if the cache is still valid, otherwise `false`.
    ///   If `.forever` is selected, this method always returns `true`.
    private func isValidCache() -> Bool {
        // If the policy is `.forever`, the cache never expires
        if cachePolicy == .forever { return true }

        let lastFetchTime = UserDefaults.standard.double(forKey: Constant.userDefaultsLastFetchKey)
        let elapsedTime = Date().timeIntervalSince1970 - lastFetchTime
        return cachePolicy.cacheDuration.map { elapsedTime < $0 } ?? false
    }
}
