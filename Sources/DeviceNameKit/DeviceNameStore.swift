//
//  DeviceNameStore.swift
//  MIT License (c) 2025 Daehee Kim
//

import Foundation

/// Persists resolved device model names in `UserDefaults`.
///
/// A name is written only after it was successfully resolved from the bundled
/// or remote data set. Unresolved identifiers are never stored, so a temporary
/// gap in the data set cannot poison the store.
struct DeviceNameStore: @unchecked Sendable {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Migrates 1.x cache entries to the v2 schema. Runs only once.
    ///
    /// A 1.x cache could contain the raw identifier itself, stored when the
    /// mapping was missing at fetch time. Such entries are discarded so the
    /// device gets re-resolved; valid names are carried over.
    func migrateIfNeeded(currentIdentifier: String) {
        guard defaults.integer(forKey: Constant.schemaVersionKey) < Constant.schemaVersion else { return }
        defer {
            defaults.removeObject(forKey: Constant.legacyDeviceNameKey)
            defaults.removeObject(forKey: Constant.legacyLastFetchKey)
            defaults.set(Constant.schemaVersion, forKey: Constant.schemaVersionKey)
        }

        guard let legacyName = defaults.string(forKey: Constant.legacyDeviceNameKey),
              legacyName != currentIdentifier else { return }

        let legacyFetchTime = defaults.double(forKey: Constant.legacyLastFetchKey)
        let resolvedAt = legacyFetchTime > 0 ? legacyFetchTime : Date().timeIntervalSince1970
        save(name: legacyName, identifier: currentIdentifier, resolvedAt: resolvedAt)
    }

    /// Returns the stored name if it belongs to the given identifier and is
    /// still valid under the given cache policy.
    func resolvedName(for identifier: String, policy: DeviceNameCachePolicy) -> String? {
        guard policy != .noCache,
              let name = defaults.string(forKey: Constant.resolvedNameKey),
              defaults.string(forKey: Constant.resolvedIdentifierKey) == identifier else { return nil }

        if policy == .forever { return name }

        guard let duration = policy.cacheDuration else { return nil }
        let resolvedAt = defaults.double(forKey: Constant.resolvedAtKey)
        let elapsed = Date().timeIntervalSince1970 - resolvedAt
        return elapsed < duration ? name : nil
    }

    /// Stores a successfully resolved name for the given identifier.
    func save(name: String, identifier: String, resolvedAt: TimeInterval = Date().timeIntervalSince1970) {
        defaults.set(name, forKey: Constant.resolvedNameKey)
        defaults.set(identifier, forKey: Constant.resolvedIdentifierKey)
        defaults.set(resolvedAt, forKey: Constant.resolvedAtKey)
        defaults.removeObject(forKey: Constant.lastRemoteMissKey)
    }

    /// Records that the remote data set did not contain the identifier yet.
    func markRemoteMiss() {
        defaults.set(Date().timeIntervalSince1970, forKey: Constant.lastRemoteMissKey)
    }

    /// Whether enough time has passed since the last remote miss to retry.
    func canRetryRemote() -> Bool {
        let lastMiss = defaults.double(forKey: Constant.lastRemoteMissKey)
        guard lastMiss > 0 else { return true }
        return Date().timeIntervalSince1970 - lastMiss >= Constant.remoteMissRetryInterval
    }
}
