import Testing
import Foundation
import Combine
@testable import DeviceNameKit

/// A `DeviceModelProvider` stub with controllable data sources.
final class StubDeviceModelProvider: DeviceModelProvider, @unchecked Sendable {
    let jsonURL = URL(string: "https://example.com/stub.json")!
    let bundledFileName = "Stub"

    private let lock = NSLock()
    var identifier: String
    var bundledModels: [String: String]
    var remoteModels: Result<[String: String], Error>
    var remoteDelay: TimeInterval = 0

    private var _remoteFetchCount = 0
    var remoteFetchCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _remoteFetchCount
    }

    init(identifier: String,
         bundledModels: [String: String] = [:],
         remoteModels: Result<[String: String], Error> = .success([:])) {
        self.identifier = identifier
        self.bundledModels = bundledModels
        self.remoteModels = remoteModels
    }

    func getDeviceIdentifier() -> String { identifier }

    func loadBundledModels() throws -> [String: String] { bundledModels }

    func fetchDeviceModels() async throws -> [String: String] {
        lock.lock()
        _remoteFetchCount += 1
        lock.unlock()
        if remoteDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(remoteDelay * 1_000_000_000))
        }
        return try remoteModels.get()
    }
}

private struct StubError: Error {}

/// Creates an isolated `UserDefaults` suite so tests do not share state.
private func makeDefaults() -> UserDefaults {
    let suiteName = "DeviceNameKitTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}

// MARK: - Local-first resolution

@Test
func bundledLookupResolvesWithoutNetwork() async throws {
    let provider = StubDeviceModelProvider(identifier: "iPhone15,2",
                                           bundledModels: ["iPhone15,2": "iPhone 14 Pro"])
    let defaults = makeDefaults()
    let fetcher = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: defaults)

    let name = try await fetcher.getDeviceName()

    #expect(name == "iPhone 14 Pro")
    #expect(provider.remoteFetchCount == 0)
    #expect(defaults.string(forKey: Constant.resolvedNameKey) == "iPhone 14 Pro")
}

@Test
func remoteFallbackResolvesDeviceNewerThanBundledData() async throws {
    let provider = StubDeviceModelProvider(identifier: "iPhone99,1",
                                           remoteModels: .success(["iPhone99,1": "iPhone Future"]))
    let defaults = makeDefaults()
    let fetcher = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: defaults)

    let name = try await fetcher.getDeviceName()
    #expect(name == "iPhone Future")
    #expect(provider.remoteFetchCount == 1)

    // A fresh instance (e.g., the next app launch) resolves from the store without networking.
    let nextLaunch = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: defaults)
    let storedName = try await nextLaunch.getDeviceName()
    #expect(storedName == "iPhone Future")
    #expect(provider.remoteFetchCount == 1)
}

// MARK: - Unresolved identifiers are never persisted

@Test
func unknownIdentifierIsNeverPersisted() async throws {
    let provider = StubDeviceModelProvider(identifier: "iPhone99,1",
                                           remoteModels: .success([:]))
    let defaults = makeDefaults()
    let fetcher = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: defaults)

    let name = try await fetcher.getDeviceName()
    #expect(name == "iPhone99,1")
    #expect(defaults.string(forKey: Constant.resolvedNameKey) == nil)

    // Within the throttle window a fresh instance answers without another remote call.
    let nextLaunch = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: defaults)
    let throttledName = try await nextLaunch.getDeviceName()
    #expect(throttledName == "iPhone99,1")
    #expect(provider.remoteFetchCount == 1)
}

@Test
func remoteMissRetriesAfterThrottleWindow() async throws {
    let provider = StubDeviceModelProvider(identifier: "iPhone99,1",
                                           remoteModels: .success([:]))
    let defaults = makeDefaults()
    let fetcher = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: defaults)
    _ = try await fetcher.getDeviceName()

    // Pretend the miss happened long ago, then simulate the repository being updated.
    defaults.set(Date().timeIntervalSince1970 - Constant.remoteMissRetryInterval - 1,
                 forKey: Constant.lastRemoteMissKey)
    provider.remoteModels = .success(["iPhone99,1": "iPhone Future"])

    let nextLaunch = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: defaults)
    let name = try await nextLaunch.getDeviceName()
    #expect(name == "iPhone Future")
    #expect(provider.remoteFetchCount == 2)
}

// MARK: - Failure behavior

@Test
func networkFailureThrowsForUnknownDevice() async throws {
    let provider = StubDeviceModelProvider(identifier: "iPhone99,1",
                                           remoteModels: .failure(StubError()))
    let fetcher = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: makeDefaults())

    await #expect(throws: DeviceNameFetcherError.self) {
        _ = try await fetcher.getDeviceName()
    }
}

@Test
func safeVariantReturnsIdentifierOnFailure() async {
    let provider = StubDeviceModelProvider(identifier: "iPhone99,1",
                                           remoteModels: .failure(StubError()))
    let fetcher = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: makeDefaults())

    let name = await fetcher.getSafeDeviceName()
    #expect(name == "iPhone99,1")
}

// MARK: - Cache policies

@Test
func noCachePolicyDoesNotPersist() async throws {
    let provider = StubDeviceModelProvider(identifier: "iPhone15,2",
                                           bundledModels: ["iPhone15,2": "iPhone 14 Pro"])
    let defaults = makeDefaults()
    let fetcher = DeviceNameFetcher(provider: provider, cachePolicy: .noCache, defaults: defaults)

    let name = try await fetcher.getDeviceName()
    #expect(name == "iPhone 14 Pro")
    #expect(defaults.string(forKey: Constant.resolvedNameKey) == nil)
}

// MARK: - 1.x migration

@Test
func poisonedLegacyCacheIsDiscarded() async throws {
    let defaults = makeDefaults()
    // A 1.x cache could contain the raw identifier itself, stored when the mapping was missing.
    defaults.set("iPhone15,2", forKey: Constant.legacyDeviceNameKey)
    defaults.set(Date().timeIntervalSince1970, forKey: Constant.legacyLastFetchKey)

    let provider = StubDeviceModelProvider(identifier: "iPhone15,2",
                                           bundledModels: ["iPhone15,2": "iPhone 14 Pro"])
    let fetcher = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: defaults)

    let name = try await fetcher.getDeviceName()
    #expect(name == "iPhone 14 Pro")
    #expect(defaults.string(forKey: Constant.legacyDeviceNameKey) == nil)
}

@Test
func validLegacyCacheIsMigrated() async throws {
    let defaults = makeDefaults()
    defaults.set("iPhone 14 Pro", forKey: Constant.legacyDeviceNameKey)
    defaults.set(Date().timeIntervalSince1970, forKey: Constant.legacyLastFetchKey)

    // No bundled or remote data — the migrated value must be used as-is.
    let provider = StubDeviceModelProvider(identifier: "iPhone15,2")
    let fetcher = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: defaults)

    let name = try await fetcher.getDeviceName()
    #expect(name == "iPhone 14 Pro")
    #expect(provider.remoteFetchCount == 0)
}

@Test
func restoredValueFromAnotherDeviceIsInvalidated() async throws {
    let defaults = makeDefaults()
    // A value resolved on a different device arrived via backup restore.
    defaults.set(Constant.schemaVersion, forKey: Constant.schemaVersionKey)
    defaults.set("iPhone 14 Pro", forKey: Constant.resolvedNameKey)
    defaults.set("iPhone15,2", forKey: Constant.resolvedIdentifierKey)
    defaults.set(Date().timeIntervalSince1970, forKey: Constant.resolvedAtKey)

    let provider = StubDeviceModelProvider(identifier: "iPad14,3",
                                           bundledModels: ["iPad14,3": "iPad Pro 11-inch (4th generation)"])
    let fetcher = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: defaults)

    let name = try await fetcher.getDeviceName()
    #expect(name == "iPad Pro 11-inch (4th generation)")
}

// MARK: - Concurrency

@Test
func concurrentCallsShareOneRemoteRequest() async throws {
    let provider = StubDeviceModelProvider(identifier: "iPhone99,1",
                                           remoteModels: .success(["iPhone99,1": "iPhone Future"]))
    provider.remoteDelay = 0.2
    let fetcher = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: makeDefaults())

    async let first = fetcher.getDeviceName()
    async let second = fetcher.getDeviceName()
    let names = try await [first, second]

    #expect(names == ["iPhone Future", "iPhone Future"])
    #expect(provider.remoteFetchCount == 1)
}

// MARK: - Synchronous access

@Test
func deviceModelResolvesSynchronouslyFromBundledData() {
    let provider = StubDeviceModelProvider(identifier: "iPhone15,2",
                                           bundledModels: ["iPhone15,2": "iPhone 14 Pro"])
    let fetcher = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: makeDefaults())

    #expect(fetcher.deviceModel == "iPhone 14 Pro")
}

// MARK: - Alternative APIs

@Test
func completionHandlerDeliversResolvedName() async {
    let provider = StubDeviceModelProvider(identifier: "iPhone15,2",
                                           bundledModels: ["iPhone15,2": "iPhone 14 Pro"])
    let fetcher = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: makeDefaults())

    let result = await withCheckedContinuation { continuation in
        fetcher.getDeviceName { continuation.resume(returning: $0) }
    }
    #expect((try? result.get()) == "iPhone 14 Pro")
}

@Test
func publisherDeliversResolvedName() async {
    let provider = StubDeviceModelProvider(identifier: "iPhone15,2",
                                           bundledModels: ["iPhone15,2": "iPhone 14 Pro"])
    let fetcher = DeviceNameFetcher(provider: provider, cachePolicy: .forever, defaults: makeDefaults())

    let name: String? = await withCheckedContinuation { continuation in
        var cancellable: AnyCancellable?
        cancellable = fetcher.getDeviceNamePublisher()
            .sink(receiveCompletion: { completion in
                if case .failure = completion { continuation.resume(returning: nil) }
                withExtendedLifetime(cancellable) { cancellable = nil }
            }, receiveValue: { name in
                continuation.resume(returning: name)
            })
    }
    #expect(name == "iPhone 14 Pro")
}

// MARK: - Bundled resources integration

@Test
func bundledResourcesAreReadable() throws {
    let providers: [any DeviceModelProvider] = [
        iOSDeviceModelProvider(),
        watchOSDeviceModelProvider(),
        macOSDeviceModelProvider(),
        tvOSDeviceModelProvider(),
        visionOSDeviceModelProvider()
    ]
    for provider in providers {
        let models = try provider.loadBundledModels()
        #expect(!models.isEmpty, "\(provider.bundledFileName).json should be bundled and non-empty")
    }

    let iOSModels = try iOSDeviceModelProvider().loadBundledModels()
    #expect(iOSModels["iPhone15,2"] == "iPhone 14 Pro")
}
