//
//  DeviceNameCachePolicy.swift
//  MIT License (c) 2025 Daehee Kim
//

import Foundation

/// A policy that determines how long the fetched device name should be cached.
///
/// `DeviceNameCachePolicy` specifies the duration for which the fetched device model name is stored.
/// When the cache expires, the data will be re-fetched from the provider.
public enum DeviceNameCachePolicy: Equatable {

    /// No caching. The device model name is always fetched anew.
    case noCache

    /// Cache the device model name for **1 day (24 hours)**.
    case oneDay

    /// Cache the device model name for **3 days (72 hours)**.
    case threeDays

    /// Cache the device model name for **7 days (1 week)**.
    case sevenDays

    /// Cache the device model name for **1 month (30 days)**.
    case oneMonth

    /// Cache the device model name **forever** (permanently stored until manually removed).
    ///
    /// This option ensures that once fetched, the device model name is never re-fetched.
    case forever

    /// A custom caching policy with a user-defined duration.
    ///
    /// - Parameter duration: The caching duration in seconds.
    case custom(TimeInterval)

    /// Returns the cache duration based on the selected policy.
    ///
    /// - Returns: The cache duration in seconds. Returns `nil` for `.noCache`, meaning no caching is applied.
    ///   If `.forever` is selected, this returns `Double.greatestFiniteMagnitude` to represent an effectively infinite duration.
    public var cacheDuration: TimeInterval? {
        switch self {
        case .noCache:
            return nil
        case .oneDay:
            return 60 * 60 * 24
        case .threeDays:
            return 60 * 60 * 24 * 3
        case .sevenDays:
            return 60 * 60 * 24 * 7
        case .oneMonth:
            return 60 * 60 * 24 * 30
        case .forever:
            return Double.greatestFiniteMagnitude
        case .custom(let duration):
            return duration
        }
    }
}
