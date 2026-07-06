//
//  DeviceNameFetcher.swift
//  MIT License (c) 2025 Daehee Kim
//

import Foundation
import Combine
import OSLog

/// Resolves and persists the device model name.
///
/// `DeviceNameFetcher` translates the device identifier (e.g., `"iPhone15,2"`)
/// into its marketing name (e.g., `"iPhone 14 Pro"`) using a local-first pipeline:
///
/// 1. A previously resolved name stored on the device.
/// 2. The data set bundled with the SDK — no network required.
/// 3. The remote data set on GitHub, consulted only when the device is newer
///    than the bundled data, so brand-new devices are covered without an app update.
///
/// Only successful lookups are stored. Once a name has been resolved it is kept
/// permanently under the default `.forever` policy and no further network
/// request is ever made.
///
/// Supported access styles: **async/await**, **completion handler**, and **Combine**.
public final class DeviceNameFetcher: Sendable {
    private let provider: DeviceModelProvider
    private let store: DeviceNameStore
    private let resolver: DeviceNameResolver
    private let cachePolicy: DeviceNameCachePolicy

    /// Creates a fetcher for the current platform.
    ///
    /// - Parameter cachePolicy: Controls how long a successfully resolved name
    ///   is persisted. The default is `.forever`, which is recommended because
    ///   a device's model name never changes.
    public convenience init(cachePolicy: DeviceNameCachePolicy = .forever) {
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

        self.init(provider: provider, cachePolicy: cachePolicy, defaults: .standard)
    }

    /// Internal initializer used for dependency injection in tests.
    init(provider: DeviceModelProvider, cachePolicy: DeviceNameCachePolicy, defaults: UserDefaults) {
        self.provider = provider
        self.cachePolicy = cachePolicy
        let store = DeviceNameStore(defaults: defaults)
        self.store = store
        self.resolver = DeviceNameResolver(provider: provider, store: store, cachePolicy: cachePolicy)
    }

    /// Warms up the resolution pipeline in the background.
    ///
    /// Calling this at app launch makes the name available by the time it is
    /// first needed. Failures are logged and never interrupt execution.
    ///
    /// - Returns: The current `DeviceNameFetcher` instance for method chaining.
    @discardableResult
    public func preload() -> Self {
        Task(priority: .utility) { [resolver] in
            do {
                let name = try await resolver.resolve()
                os_log("Device model resolved: %@", log: .default, type: .info, name)
            } catch {
                os_log("DeviceNameFetcher preload error: %@", log: .default, type: .error, error.localizedDescription)
            }
        }
        return self
    }

    /// Resolves the device model name asynchronously.
    ///
    /// - Returns: The model name, or the raw identifier when the device is not
    ///   part of any data set yet. In that case resolution is retried on later
    ///   calls, and the identifier is never persisted as if it were a name.
    /// - Throws: `DeviceNameFetcherError.fetchFailed` when the identifier is
    ///   unknown locally and the remote request fails.
    public func getDeviceName() async throws -> String {
        try await resolver.resolve()
    }

    /// Resolves the device model name asynchronously without throwing.
    ///
    /// If resolution fails, the raw device identifier is returned instead and
    /// the failure is logged for debugging purposes.
    ///
    /// - Returns: The model name, or the raw device identifier in case of failure.
    public func getSafeDeviceName() async -> String {
        do {
            return try await resolver.resolve()
        } catch {
            let identifier = provider.getDeviceIdentifier()
            os_log("Failed to resolve device model name: %@ (identifier: %@)", log: .default, type: .error, error.localizedDescription, identifier)
            return identifier
        }
    }

    /// Resolves the device model name using a completion handler.
    ///
    /// - Parameter completion: A closure that receives the model name or a
    ///   `DeviceNameFetcherError`.
    public func getDeviceName(completion: @escaping @Sendable (Result<String, DeviceNameFetcherError>) -> Void) {
        Task { [resolver, provider] in
            do {
                completion(.success(try await resolver.resolve()))
            } catch let error as DeviceNameFetcherError {
                completion(.failure(error))
            } catch {
                completion(.failure(.fetchFailed(deviceIdentifier: provider.getDeviceIdentifier(), underlyingError: error)))
            }
        }
    }

    /// Resolves the device model name using the Combine API.
    ///
    /// - Returns: A publisher that emits the model name or a `DeviceNameFetcherError`.
    ///   The resolution starts when the publisher is subscribed to.
    public func getDeviceNamePublisher() -> AnyPublisher<String, DeviceNameFetcherError> {
        Deferred { [resolver, provider] in
            Future { promise in
                Task {
                    do {
                        promise(.success(try await resolver.resolve()))
                    } catch let error as DeviceNameFetcherError {
                        promise(.failure(error))
                    } catch {
                        promise(.failure(.fetchFailed(deviceIdentifier: provider.getDeviceIdentifier(), underlyingError: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// The device model name, if it can be determined without a network request.
    ///
    /// Returns the persisted resolved name when available, falling back to a
    /// synchronous lookup in the bundled data set. Returns `nil` only for
    /// devices unknown to the local data that have not been resolved remotely yet.
    public var deviceModel: String? {
        let identifier = provider.getDeviceIdentifier()
        store.migrateIfNeeded(currentIdentifier: identifier)

        if let stored = store.resolvedName(for: identifier, policy: cachePolicy) {
            return stored
        }
        guard let bundled = try? provider.loadBundledModels() else { return nil }
        return bundled[identifier]
    }
}
