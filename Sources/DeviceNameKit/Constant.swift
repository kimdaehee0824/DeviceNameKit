//
//  Constant.swift
//  MIT License (c) 2025 Daehee Kim
//

import Foundation

/// A structure that defines constant values used in the library.
struct Constant {

    /// The base URL path for fetching the latest device model name list.
    ///
    /// The remote data is consulted only when the current device identifier is
    /// not part of the bundled data set (i.e., the device is newer than the SDK).
    ///
    /// - Note: If you fork this repository, make sure to change `kimdaehee0824`
    ///   to your own repository name.
    static let modelNamePath: String = "https://raw.githubusercontent.com/kimdaehee0824/DeviceNameKit/main/DeviceName/"

    /// The subdirectory inside the resource bundle that contains the bundled JSON files.
    static let bundledDataDirectory = "DeviceName"

    /// The minimum interval between remote lookups after the remote data set
    /// was fetched successfully but did not contain the current identifier.
    static let remoteMissRetryInterval: TimeInterval = 60 * 60

    // MARK: - UserDefaults keys (storage schema v2)

    /// Stores the successfully resolved device model name.
    static let resolvedNameKey = "devicenamekit.resolved_name"

    /// Stores the device identifier the resolved name belongs to.
    /// Used to invalidate values restored from another device's backup.
    static let resolvedIdentifierKey = "devicenamekit.resolved_identifier"

    /// Stores the timestamp of the successful resolution.
    static let resolvedAtKey = "devicenamekit.resolved_at"

    /// Stores the timestamp of the last remote miss, used for retry throttling.
    static let lastRemoteMissKey = "devicenamekit.last_remote_miss"

    /// Stores the storage schema version, used for the one-time 1.x migration.
    static let schemaVersionKey = "devicenamekit.schema_version"

    /// The current storage schema version.
    static let schemaVersion = 2

    // MARK: - Legacy UserDefaults keys (1.x)

    /// The 1.x key that stored the cached device name.
    static let legacyDeviceNameKey = "device_name_cache"

    /// The 1.x key that stored the last fetch timestamp.
    static let legacyLastFetchKey = "device_name_last_fetch"
}
