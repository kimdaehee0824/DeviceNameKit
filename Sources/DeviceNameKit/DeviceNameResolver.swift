//
//  DeviceNameResolver.swift
//  MIT License (c) 2025 Daehee Kim
//

import Foundation

/// Resolves the current device's model name using a local-first pipeline.
///
/// Resolution order:
/// 1. A previously resolved name persisted in `DeviceNameStore`.
/// 2. The data set bundled with the package.
/// 3. The remote data set on GitHub — attempted only for identifiers unknown
///    to the bundled data (i.e., devices newer than the installed SDK).
///
/// Only successful lookups are persisted. When every source misses, the raw
/// identifier is returned and resolution is retried after
/// `Constant.remoteMissRetryInterval`, including within the same process.
actor DeviceNameResolver {
    private let provider: DeviceModelProvider
    private let store: DeviceNameStore
    private let cachePolicy: DeviceNameCachePolicy

    /// The name resolved during this process's lifetime.
    /// Never set under `.noCache`, which re-resolves on every call.
    private var memoizedName: String?

    /// The bundled data set, decoded once per resolver lifetime.
    /// The app bundle cannot change while the process is running.
    private var cachedBundledModels: [String: String]?

    private var inFlight: Task<String, Error>?

    init(provider: DeviceModelProvider, store: DeviceNameStore, cachePolicy: DeviceNameCachePolicy) {
        self.provider = provider
        self.store = store
        self.cachePolicy = cachePolicy
    }

    /// Resolves the device model name.
    ///
    /// - Returns: The resolved model name, or the raw identifier when the
    ///   identifier is not known to any data source yet.
    /// - Throws: `DeviceNameFetcherError.fetchFailed` when no local answer
    ///   exists and the remote request fails.
    func resolve() async throws -> String {
        if let memoizedName { return memoizedName }
        if let inFlight { return try await inFlight.value }

        let task = Task { try await performResolution() }
        inFlight = task
        defer { inFlight = nil }
        return try await task.value
    }

    private func performResolution() async throws -> String {
        let identifier = provider.getDeviceIdentifier()

        if let stored = store.resolvedName(for: identifier, policy: cachePolicy) {
            memoizedName = stored
            return stored
        }

        if let name = bundledModels()[identifier] {
            persist(name: name, identifier: identifier)
            return name
        }

        guard store.canRetryRemote() else {
            return identifier
        }

        do {
            let remote = try await provider.fetchDeviceModels()
            if let name = remote[identifier] {
                persist(name: name, identifier: identifier)
                return name
            }
            store.markRemoteMiss()
            return identifier
        } catch {
            throw DeviceNameFetcherError.fetchFailed(deviceIdentifier: identifier, underlyingError: error)
        }
    }

    private func bundledModels() -> [String: String] {
        if let cachedBundledModels { return cachedBundledModels }
        let models = (try? provider.loadBundledModels()) ?? [:]
        cachedBundledModels = models
        return models
    }

    private func persist(name: String, identifier: String) {
        guard cachePolicy != .noCache else { return }
        memoizedName = name
        store.save(name: name, identifier: identifier)
    }
}
