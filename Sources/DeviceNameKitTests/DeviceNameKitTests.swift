import Testing
import Foundation
@testable import DeviceNameKit

/// Test `DeviceNameFetcher` with async/await
@Test
func testDeviceNameFetcher_CacheDisabled() async throws {
    let fetcher = DeviceNameFetcher(cachePolicy: .noCache)
    let modelName = try await fetcher.getDeviceName()

    #expect(modelName == "iPhone 15 Pro", "Device model name should match expected value.")
}

/// Test caching behavior of `DeviceNameFetcher`
@Test
func testDeviceNameFetcher_CacheEnabled() async throws {
    let fetcher = DeviceNameFetcher(cachePolicy: .oneDay)

    // First call: Fetches data from the provider
    let firstFetch = try await fetcher.getDeviceName()
    #expect(firstFetch == "iPhone 15 Pro", "First fetch should return correct device model.")

    // Second call: Should return cached data
    let secondFetch = try await fetcher.getDeviceName()
    #expect(secondFetch == "iPhone 15 Pro", "Second fetch should use cached data.")
}

/// Test cache expiration logic
@Test
func testDeviceNameFetcher_InvalidCache() async throws {
    let fetcher = DeviceNameFetcher(cachePolicy: .custom(-1)) // Cache expires immediately

    // First call: Fetches data
    let firstFetch = try await fetcher.getDeviceName()
    #expect(firstFetch == "iPhone 15 Pro", "First fetch should return correct device model.")

    // Second call: Cache should be invalidated, so it fetches again
    let secondFetch = try await fetcher.getDeviceName()
    #expect(secondFetch == "iPhone 15 Pro", "Second fetch should refetch due to cache expiration.")
}

/// Test `DeviceNameFetcher` using completion handler
@Test
func testDeviceNameFetcher_CompletionHandler() async throws {
    let fetcher = DeviceNameFetcher(cachePolicy: .noCache)
    fetcher.getDeviceName { result in
        switch result {
        case .success(let modelName):
            #expect(modelName == "iPhone 15 Pro", "Completion handler should return correct model.")
        case .failure(let error):
            #expect(false, "Completion handler should not fail: \(error)")
        }
    }
}

/// Test `DeviceNameFetcher` using Combine Publisher
@Test
func testDeviceNameFetcher_CombinePublisher() async throws {
    let fetcher = DeviceNameFetcher(cachePolicy: .noCache)
    _ = fetcher.getDeviceNamePublisher()
        .sink(receiveCompletion: { result in
            switch result {
            case .failure(let error):
                #expect(false, "Combine publisher should not fail: \(error)")
            case .finished:
                break
            }
        }, receiveValue: { modelName in
            #expect(modelName == "iPhone 15 Pro", "Combine publisher should return correct model.")
        })
}
