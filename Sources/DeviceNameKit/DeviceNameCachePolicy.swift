//
//  DeviceNameCachePolicy.swift
//  MIT License (c) 2025 Daehee Kim
//

import Foundation

/// A policy that determines how long a successfully resolved device name is persisted.
///
/// Only successful lookups are ever stored — an identifier that could not be
/// resolved is never written, regardless of the policy. Because a device's
/// model name never changes, `.forever` (the default) is recommended.
public enum DeviceNameCachePolicy: Equatable, Sendable {

    /// Never persists the resolved name. The name is re-resolved on every use,
    /// starting from the bundled data set.
    case noCache

    /// Persists the resolved name for **1 day (24 hours)**.
    case oneDay

    /// Persists the resolved name for **3 days (72 hours)**.
    case threeDays

    /// Persists the resolved name for **7 days (1 week)**.
    case sevenDays

    /// Persists the resolved name for **1 month (30 days)**.
    case oneMonth

    /// Persists the resolved name **forever** (recommended).
    ///
    /// Once a name has been resolved, it is never re-fetched.
    case forever

    /// A custom persistence policy with a user-defined duration.
    ///
    /// - Parameter duration: The persistence duration in seconds.
    case custom(TimeInterval)

    /// Returns the persistence duration based on the selected policy.
    ///
    /// - Returns: The duration in seconds. Returns `nil` for `.noCache`,
    ///   meaning no persistence is applied. If `.forever` is selected, this
    ///   returns `Double.greatestFiniteMagnitude` to represent an effectively
    ///   infinite duration.
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
