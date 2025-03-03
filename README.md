![Logo image](Asset/DeviceNameKit_banner.png)

> You can view the document in different languages: [English](README.md), [한국어](README_ko.md), [日本語](README_jp.md)

**DeviceNameKit** is a powerful SDK that converts Apple device **identifiers (Device Identifier) into commercial model names (Device Model Name)**. It supports all Apple platforms, including iPhone, iPad, Mac, Apple TV, Vision Pro, and Apple Watch, and automatically maps the latest device information to provide intuitive model names.

This library converts Apple's internal device identifiers (e.g., `iPhone15,2`) into user-friendly product names (e.g., `iPhone 14 Pro`). Additionally, it includes a **UserDefaults-based caching feature** to minimize unnecessary network requests and optimize performance.

**DeviceNameKit** offers multiple data retrieval methods, allowing developers to choose the most suitable approach for their needs.

- **Supports async/await:** Leverages Swift Concurrency for clean and intuitive asynchronous handling
- **Supports Completion Handler:** Enables flexible data retrieval using the traditional callback pattern
- **Supports Combine API:** Implements a reactive data flow using `Future`
- **Caching feature:** Stores device model data to prevent repeated API calls and improve performance
- **Reliable data retrieval:** The `getSafeDeviceName()` method ensures the app continues to function correctly even if a network error occurs by returning the original device identifier

This SDK is useful in various scenarios where the app needs to correctly recognize the device model name, such as **applying device-specific settings, log analysis, A/B testing, and customer support emails.**

To check out the demo app, click [here](https://github.com/kimdaehee0824/DeviceNameKit_Demo).

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
3. After adding the dependency, you can use DeviceNameKit by importing it:
   ```swift
   import DeviceNameKit
   ```

## Usage

### 1. Basic Device Model Name Conversion (`async/await`)
```swift
let fetcher = DeviceNameFetcher(cachePolicy: .oneDay)

Task {
    do {
        let modelName = try await fetcher.getDeviceName()
        print("Device Model Name: \(modelName)") // e.g., iPhone 15 Pro
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}
```

### 2. Using Completion Handler
```swift
let fetcher = DeviceNameFetcher(cachePolicy: .oneDay)

fetcher.getDeviceName { result in
    switch result {
    case .success(let modelName):
        print("Device Model Name: \(modelName)")
    case .failure(let error):
        print("Error: \(error.localizedDescription)")
    }
}
```

### 3. Using Combine API
```swift
import Combine

let fetcher = DeviceNameFetcher(cachePolicy: .oneDay)

let cancellable = fetcher.getDeviceNamePublisher()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("Error: \(error)")
        }
    }, receiveValue: { modelName in
        print("Device Model Name: \(modelName)")
    })
```

### 4. Function That Does Not Emit Errors (`getSafeDeviceName`)
Using `getSafeDeviceName()`, the original device identifier is returned if an error occurs, making error handling unnecessary.

```swift
let fetcher = DeviceNameFetcher(cachePolicy: .oneDay)

Task {
    let modelName = await fetcher.getSafeDeviceName()
    print("Device Model Name: \(modelName)")
}
```
This method internally logs failures using `os.log` while returning the original device identifier.

### 5. Preloading with `preload()`
Calling `preload()` allows the device model name to be retrieved and cached in advance by communicating with the server.

```swift
let fetcher = DeviceNameFetcher(cachePolicy: .threeDays)
fetcher.preload() // Optimize performance by preloading at app launch
```

### 6. Accessing via `deviceModel` Property
After calling `preload()`, the model name can be accessed directly as a `String` after a certain time. If the server communication is incomplete or has failed, it returns `nil`.

```swift
print("Current Device Model Name: \(fetcher.deviceModel ?? "Unknown")")
```

## Caching Policy
| Policy | Description |
|---|---|
| `.noCache` | Always fetches the latest data |
| `.oneDay` | Caches data for 1 day |
| `.threeDays` | Caches data for 3 days |
| `.sevenDays` | Caches data for 7 days |
| `.oneMonth` | Caches data for 1 month |
| `.custom(TimeInterval)` | Custom caching duration |
| `.forever` | Caches data permanently |

### Applying Caching
```swift
let fetcher = DeviceNameFetcher(cachePolicy: .threeDays)
```
With this configuration, the same device returns cached model names for 3 days, after which the data is refreshed.
Since device model names rarely change, permanent caching is recommended.

If caching is not set, the latest data is always fetched.

## Error Handling
The `DeviceNameFetcherError` enum provides error details.

```swift
public enum DeviceNameFetcherError: Error {
    case fetchFailed(deviceIdentifier: String, underlyingError: Error)
}
```
When an error occurs, `deviceIdentifier` (e.g., "iPhone17,4") and the `underlyingError` can be inspected.

## How It Works
1. **Retrieve Device Identifier:** The current device's identifier is obtained using `uname()` or `sysctlbyname("hw.model")`.
2. **Map to Device Model Name:** The JSON data stored in this GitHub repository is referenced to obtain the latest device model name. The JSON files are located in the `DeviceName` folder, categorized by OS.

## Contribution

1. Please submit issues or feature requests under the `Issues` tab.
2. Pull requests are always welcome. If you work on changes or new features, we will review them and add them to future versions.

> [!NOTE]
> If updates to this repository are slow, or if you prefer to manage the JSON data yourself, fork this repository and update it directly.

## License

This project is distributed under the MIT License. For details, refer to the [`LICENSE`](LICENSE) file.

