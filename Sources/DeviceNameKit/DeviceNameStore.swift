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
    private let lock = NSLock()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Migrates 1.x cache entries to the v2 schema. Runs only once.
    ///
    /// A legacy value is carried over only when it matches `verifiedName` —
    /// the name the bundled data set reports for the current identifier.
    /// Anything else is discarded so the device gets re-resolved: the raw
    /// identifier stored during a 1.x data gap, or a name that arrived from
    /// another device's backup and does not belong to this hardware.
    func migrateIfNeeded(currentIdentifier: String, verifiedName: String?) {
        lock.lock()
        defer { lock.unlock() }

        guard defaults.integer(forKey: Constant.schemaVersionKey) < Constant.schemaVersion else { return }
        defer {
            defaults.removeObject(forKey: Constant.legacyDeviceNameKey)
            defaults.removeObject(forKey: Constant.legacyLastFetchKey)
            defaults.set(Constant.schemaVersion, forKey: Constant.schemaVersionKey)
        }

        guard let legacyName = defaults.string(forKey: Constant.legacyDeviceNameKey),
              let verifiedName, legacyName == verifiedName else { return }

        let legacyFetchTime = defaults.double(forKey: Constant.legacyLastFetchKey)
        let resolvedAt = legacyFetchTime > 0 ? legacyFetchTime : Date().timeIntervalSince1970
        write(name: legacyName, identifier: currentIdentifier, resolvedAt: resolvedAt)
    }

    /// Returns the stored name if it belongs to the given identifier and is
    /// still valid under the given cache policy.
    func resolvedName(for identifier: String, policy: DeviceNameCachePolicy) -> String? {
        lock.lock()
        defer { lock.unlock() }

        guard policy != .noCache,
              let name = defaults.string(forKey: Constant.resolvedNameKey),
              defaults.string(forKey: Constant.resolvedIdentifierKey) == identifier else { return nil }

        if policy == .forever { return name }

        guard let duration = policy.cacheDuration else { return nil }
        let resolvedAt = defaults.double(forKey: Constant.resolvedAtKey)
        // Clamp so a resolution timestamp in the future (backward clock change)
        // is treated as "just resolved" rather than staying valid indefinitely.
        let elapsed = max(0, Date().timeIntervalSince1970 - resolvedAt)
        return elapsed < duration ? name : nil
    }

    /// Stores a successfully resolved name for the given identifier.
    func save(name: String, identifier: String, resolvedAt: TimeInterval = Date().timeIntervalSince1970) {
        lock.lock()
        defer { lock.unlock() }
        write(name: name, identifier: identifier, resolvedAt: resolvedAt)
    }

    /// Records that the remote data set did not contain the identifier yet.
    func markRemoteMiss() {
        lock.lock()
        defer { lock.unlock() }
        defaults.set(Date().timeIntervalSince1970, forKey: Constant.lastRemoteMissKey)
    }

    /// Whether enough time has passed since the last remote miss to retry.
    func canRetryRemote() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let lastMiss = defaults.double(forKey: Constant.lastRemoteMissKey)
        guard lastMiss > 0 else { return true }

        let now = Date().timeIntervalSince1970
        // A miss recorded in the future means the clock moved backward since;
        // do not let a bogus timestamp block retries indefinitely.
        guard lastMiss <= now else { return true }
        return now - lastMiss >= Constant.remoteMissRetryInterval
    }

    /// Writes the resolved entry. Callers must hold `lock`.
    private func write(name: String, identifier: String, resolvedAt: TimeInterval) {
        defaults.set(name, forKey: Constant.resolvedNameKey)
        defaults.set(identifier, forKey: Constant.resolvedIdentifierKey)
        defaults.set(resolvedAt, forKey: Constant.resolvedAtKey)
        defaults.removeObject(forKey: Constant.lastRemoteMissKey)
    }
}
