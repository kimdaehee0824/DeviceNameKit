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
/// identifier is returned and resolution is retried later, throttled by
/// `Constant.remoteMissRetryInterval`.
actor DeviceNameResolver {
    private let provider: DeviceModelProvider
    private let store: DeviceNameStore
    private let cachePolicy: DeviceNameCachePolicy

    /// The name resolved during this process's lifetime.
    private var memoizedName: String?

    /// Set when the remote data was fetched successfully but did not contain
    /// the identifier; suppresses further remote calls within this session.
    private var remoteMissedThisSession = false

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
        store.migrateIfNeeded(currentIdentifier: identifier)

        if let stored = store.resolvedName(for: identifier, policy: cachePolicy) {
            memoizedName = stored
            return stored
        }

        if let bundled = try? provider.loadBundledModels(), let name = bundled[identifier] {
            persist(name: name, identifier: identifier)
            return name
        }

        guard remoteMissedThisSession == false, store.canRetryRemote() else {
            return identifier
        }

        do {
            let remote = try await provider.fetchDeviceModels()
            if let name = remote[identifier] {
                persist(name: name, identifier: identifier)
                return name
            }
            remoteMissedThisSession = true
            store.markRemoteMiss()
            return identifier
        } catch {
            throw DeviceNameFetcherError.fetchFailed(deviceIdentifier: identifier, underlyingError: error)
        }
    }

    private func persist(name: String, identifier: String) {
        memoizedName = name
        if cachePolicy != .noCache {
            store.save(name: name, identifier: identifier)
        }
    }
}
