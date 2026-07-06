![Logo image](Asset/DeviceNameKit_banner.png)

> You can view the document in different languages: [English](README.md), [한국어](README_ko.md), [日本語](README_jp.md)

**DeviceNameKit** is an SDK that converts Apple **device identifiers into commercial model names**. It supports every Apple platform: iPhone, iPad, Mac, Apple Watch, Apple TV, and Vision Pro.

The library translates Apple's internal device identifiers (e.g., `iPhone15,2`) into user-friendly product names (e.g., `iPhone 14 Pro`). The mapping data ships inside the SDK, so **most devices are resolved instantly without any network request**. Only devices newer than the bundled data are looked up remotely, which means **brand-new devices are covered without an app update**.

- **Local-first resolution:** Works offline thanks to the bundled data set
- **Automatic coverage of new devices:** Only identifiers missing from the bundled data are looked up remotely — no app update required
- **Resolve once, keep forever:** Only successful lookups are persisted; after that, no network request is ever made
- **async/await support:** Clean, intuitive asynchronous handling with Swift Concurrency
- **Completion handler support:** The traditional callback pattern works as well
- **Combine API support:** A reactive flow that starts on subscription
- **Safe lookup:** `getSafeDeviceName()` returns the raw device identifier on failure, so your app keeps working

The SDK is useful wherever the exact device model name matters: **device-specific settings, log analysis, A/B testing, and customer support.**

To check out the demo app, click [here](https://github.com/kimdaehee0824/DeviceNameKit_Demo).

## What's New in 2.0

v2.0.0 rebuilds the lookup flow around a local-first pipeline. **The public API is unchanged, so you can update without touching your code.**

- The device data set is bundled with the SDK, so it works offline and in restricted network environments.
- The remote data set is consulted only for devices newer than the bundled data.
- Only successfully resolved names are persisted. An identifier without a mapping yet is never stored, and resolution retries automatically once the data is updated.
- Caches written by 1.x are migrated automatically; corrupted entries that stored the raw identifier are discarded and re-resolved.
- The default cache policy changed from `.noCache` to `.forever` — a device's model name never changes, so permanent storage is the right default.
- On the simulator, the simulated device's model name is returned instead of the host architecture (`arm64`).

## Supported Platforms

| OS       | Minimum Supported Version |
| -------- | ------------------------ |
| iOS      | 13.0+                     |
| macOS    | 11.0+                     |
| watchOS  | 6.0+                      |
| tvOS     | 13.0+                     |
| visionOS | 1.0+                      |

## Installation

### Swift Package Manager (SPM)

1. In Xcode, select `File > Add Packages...`
2. Enter the following URL to add the package:
   ```
   https://github.com/kimdaehee0824/DeviceNameKit.git
   ```
3. Choose version `2.0.0` or later, then use the package with:
   ```swift
   import DeviceNameKit
   ```

## Usage

### 1. Basic Device Model Name Conversion (`async/await`)
```swift
let fetcher = DeviceNameFetcher() // default policy: .forever

Task {
    do {
        let modelName = try await fetcher.getDeviceName()
        print("Device Model Name: \(modelName)") // e.g., iPhone 14 Pro
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}
```

### 2. Using a Completion Handler
```swift
let fetcher = DeviceNameFetcher()

fetcher.getDeviceName { result in
    switch result {
    case .success(let modelName):
        print("Device Model Name: \(modelName)")
    case .failure(let error):
        print("Error: \(error.localizedDescription)")
    }
}
```

### 3. Using the Combine API
```swift
import Combine

let fetcher = DeviceNameFetcher()

let cancellable = fetcher.getDeviceNamePublisher()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Error: \(error)")
        }
    }, receiveValue: { modelName in
        print("Device Model Name: \(modelName)")
    })
```

### 4. A Function That Never Throws (`getSafeDeviceName`)
`getSafeDeviceName()` returns the raw device identifier when resolution fails, so it is a good fit when you do not need explicit error handling.

```swift
let fetcher = DeviceNameFetcher()

Task {
    let modelName = await fetcher.getSafeDeviceName()
    print("Device Model Name: \(modelName)")
}
```
On failure this method returns the original device identifier and logs the error via `os.log`.

### 5. Preloading with `preload()`
Calling `preload()` resolves the model name in the background. Call it at app launch and the value is ready by the time you need it.

```swift
let fetcher = DeviceNameFetcher()
fetcher.preload() // resolve ahead of time at app launch
```

### 6. Synchronous Access via the `deviceModel` Property
Returns the model name from the persisted value or the bundled data set, without any network request. It returns `nil` only for a device missing from the bundled data that has not been resolved remotely yet.

```swift
print("Current Device Model Name: \(fetcher.deviceModel ?? "Unknown")")
```

## Cache Policy

The cache policy controls **how long a successfully resolved name is persisted on the device**. An identifier that could not be resolved is never stored, regardless of the policy.

| Policy | Description |
|---|---|
| `.forever` (default) | Keeps a resolved name permanently — recommended |
| `.oneDay` | Persists for 1 day |
| `.threeDays` | Persists for 3 days |
| `.sevenDays` | Persists for 7 days |
| `.oneMonth` | Persists for 1 month |
| `.custom(TimeInterval)` | Custom duration |
| `.noCache` | Never persists; re-resolves every time (the bundled data is still used first) |

A device's model name never changes, so we recommend keeping the default `.forever`.

```swift
let fetcher = DeviceNameFetcher(cachePolicy: .forever)
```

## Error Handling
The `DeviceNameFetcherError` enum provides error details.

```swift
public enum DeviceNameFetcherError: Error {
    case fetchFailed(deviceIdentifier: String, underlyingError: Error)
}
```
When an error occurs, you can inspect the `deviceIdentifier` (e.g., `"iPhone15,2"`) and the `underlyingError`. This error is thrown only when a device unknown to the local data fails to be resolved remotely.

## How It Works
1. **Read the device identifier:** The identifier is obtained via `uname()` or `sysctlbyname("hw.model")`.
2. **Check the persisted value:** If a previously resolved name is stored on the device, it is returned immediately.
3. **Look up the bundled data:** The identifier is searched in the JSON data shipped with the SDK. Most devices are resolved here with zero network traffic.
4. **Look up the remote data:** Only for devices missing from the bundled data, the latest JSON in this repository's `DeviceName` folder is fetched. If the identifier is not there yet either, the raw identifier is returned and resolution retries after a cool-down (1 hour).

Because only successful lookups are stored, a temporary gap in the data set can never poison the persisted value.

## Upgrading from 1.x

Just bump the version — no code changes are required. Keep these behavior changes in mind:

- The default cache policy is now `.forever`. To keep the old default, pass `DeviceNameFetcher(cachePolicy: .noCache)` explicitly.
- Caches written by 1.x are migrated automatically on first run. Entries that stored the raw identifier during a data gap are discarded and re-resolved correctly.
- The `DeviceName/` folder and its JSON schema remain unchanged in this repository, so 1.x clients keep working.

## Contribution

1. Please submit issues or feature requests under the `Issues` tab.
2. Pull requests are always welcome. We will review them and include them in a future version.
3. When updating device data, edit the JSON in the `DeviceName/` folder and run `Scripts/sync-device-data.sh` to sync the bundled resources. CI fails when the two locations differ.

> [!NOTE]
> If updates to this repository are slow, or if you prefer to manage the JSON data yourself, fork this repository and point `modelNamePath` in `Constant.swift` to your fork.

## License

This project is distributed under the MIT License. For details, refer to the [`LICENSE`](LICENSE) file.
