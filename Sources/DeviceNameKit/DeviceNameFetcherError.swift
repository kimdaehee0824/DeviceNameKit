//
//  DeviceNameFetcherError.swift
//  MIT License (c) 2025 Daehee Kim
//

import Foundation

/// An error type that may occur in `DeviceNameFetcher`.
///
/// This error is thrown when retrieving the device model information fails.
/// It includes the original device identifier and the underlying error for debugging purposes.
public enum DeviceNameFetcherError: Error {

    /// An error indicating that fetching the device model name has failed.
    ///
    /// - Parameters:
    ///   - deviceIdentifier: The original device identifier (e.g., `"iPhone17,4"`).
    ///   - underlyingError: The actual error that caused the failure.
    case fetchFailed(deviceIdentifier: String, underlyingError: Error)

    /// Returns a localized description of the error.
    public var localizedDescription: String {
        switch self {
        case .fetchFailed(let deviceIdentifier, let error):
            return "Failed to fetch device model for identifier \(deviceIdentifier): \(error.localizedDescription)"
        }
    }
}
