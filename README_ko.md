![Logo image](Asset/DeviceNameKit_banner.png)

You can view the document in different languages: [English](README.md), [한국어](README.md), [日本語](README.md)

**DeviceNameKit**은 Apple 기기의 **기기 식별자(Device Identifier)를 상업용 모델명(Device Model Name)으로 변환**하는 강력한 SDK입니다. iPhone, iPad, Mac, Apple Watch 등 모든 Apple 플랫폼에서 사용 가능하며, 최신 기기 정보를 자동으로 매핑하여 직관적인 모델명을 제공합니다.

이 라이브러리는 Apple이 사용하는 내부 기기 식별자(예: `iPhone15,2`)를 사용자가 이해하기 쉬운 제품명(예: `iPhone 14 Pro`)으로 변환하는 기능을 제공합니다. 또한, **UserDefaults 기반의 캐싱 기능**을 통해 불필요한 네트워크 요청을 최소화하고, 성능을 최적화할 수 있습니다.

**DeviceNameKit**은 다양한 방식으로 데이터를 제공하여 개발자의 요구에 맞는 최적의 사용 방식을 선택할 수 있도록 설계되었습니다. 

- **비동기(async/await) 방식 지원**: 최신 Swift Concurrency를 활용하여 깔끔하고 직관적인 비동기 처리 가능
- **Completion Handler 방식 지원**: 기존 콜백 패턴을 활용한 유연한 데이터 요청
- **Combine API 지원**: `Future` 기반의 반응형 데이터 흐름 구현 가능
- **캐싱 기능 제공**: 기기 모델명 데이터를 저장하여 반복적인 API 호출을 방지하고 성능을 향상
- **안정적인 데이터 조회**: `getSafeDeviceName()`을 사용하면 네트워크 오류 발생 시에도 기본 기기 식별자를 반환하여 앱의 정상적인 동작을 유지

이 SDK는 앱 내에서 기기 모델명을 사용자가 정확하게 파악해야 하는 경우, 예를 들어 **디바이스별 설정 적용, 로그 분석, A/B 테스트, CS 메일 등 다양한 용도**에 활용할 수 있습니다.

## 지원 플랫폼

| OS       | 최소 지원 버전 |
| -------- | -------- |
| iOS      | 13.0+    |
| macOS    | 11.0+    |
| watchOS  | 6.0+     |
| tvOS     | 13.0+    |
| visionOS | 1.0+     |

## 설치 방법

### Swift Package Manager (SPM)

1. Xcode에서 `File > Add Packages...` 를 선택해주세요
2. 다음 URL을 입력하여 패키지를 추가해주세요
   ```
   https://github.com/kimdaehee0824/DeviceNameKit.git
   ```
3. Dependency 추가 후 `import DeviceNameKit` 를 사용하여 DeviceNameKit를 사용할 수 있습니다. 

## 사용법
### 1. 기본적인 기기 모델명 변환 (`async/await`)
```swift
import DeviceNameKit

let fetcher = DeviceNameFetcher(cachePolicy: .oneDay)

Task {
    do {
        let modelName = try await fetcher.getDeviceName()
        print("기기 모델명: \(modelName)") // 예: iPhone 15 Pro
    } catch {
        print("오류 발생: \(error.localizedDescription)")
    }
}
```

### 2. Completion Handler 방식 사용
```swift
fetcher.getDeviceName { result in
    switch result {
    case .success(let modelName):
        print("기기 모델명: \(modelName)")
    case .failure(let error):
        print("오류 발생: \(error.localizedDescription)")
    }
}
```

### 3. Combine API 사용
```swift
import Combine

let cancellable = fetcher.getDeviceNamePublisher()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("오류 발생: \(error)")
        }
    }, receiveValue: { modelName in
        print("기기 모델명: \(modelName)")
    })
```

### 4. 오류를 방출하지 않는 함수 (`getSafeDeviceName`)
`getSafeDeviceName()`을 사용하면 오류가 발생하더라도 기본 기기 식별자를 반환하여 에러 핸들링이 필요 없다면 해당 코드를 사용하는 것이 좋습니다.

```swift
Task {
    let modelName = await fetcher.getSafeDeviceName()
    print("기기 모델명: \(modelName)")
}
```
이 메서드는 내부적으로 오류 발생 시 원래의 기기 식별자를 반환하고, `os.log`로 실패 로그를 기록합니다.

### 5. `preload()`를 활용한 사전 로드
`preload()`함수를 호출하면 서버와 미리 통신하여 기기 모델명을 미리 가져와 캐싱할 수 있습니다.

```swift
let fetcher = DeviceNameFetcher(cachePolicy: .threeDays)
fetcher.preload() // 앱 시작 시 미리 로드하여 성능 최적화
```

### 6. `deviceModel` 속성으로 간편하게 접근
`preload()` 이후, 일정 시간 후 모델명을 `String` 값으로 바로 접근할 수 있습니다. 
서버 통신이 완료되지 않았거나 실패한 경우 `nil`을 반환합니다.

```swift
print("현재 기기 모델명: \(fetcher.deviceModel ?? "불명")")
```

## 캐싱 정책
| 정책 | 설명 |
|---|---|
| `.noCache` | 항상 최신 데이터를 가져옴 |
| `.oneDay` | 1일간 캐싱 유지 |
| `.threeDays` | 3일간 캐싱 유지 |
| `.sevenDays` | 7일간 캐싱 유지 |
| `.oneMonth` | 1개월간 캐싱 유지 |
| `.custom(TimeInterval)` | 사용자 지정 기간 |
| `.forever` | 영구적으로 캐싱 |

### 캐싱 적용 예시
```swift
let fetcher = DeviceNameFetcher(cachePolicy: .threeDays)
```
위와 같이 설정하면, 3일 동안 동일한 기기에서는 캐싱된 모델명을 반환하며 이후에는 다시 데이터를 갱신합니다.
기본적으로 휴대폰이 바뀌지 않는 이상 값이 변하지 않기 때문에. 영구 캐싱을 권장합니다.

케싱을 설정하지 않으면 항상 최신 데이터를 가져옵니다.

## 에러 처리
`DeviceNameFetcherError` 열거형을 통해 발생한 에러를 확인할 수 있습니다.

```swift
public enum DeviceNameFetcherError: Error {
    case fetchFailed(deviceIdentifier: String, underlyingError: Error)
}
```
에러가 발생한 경우 `deviceIdentifier`(예: "iPhone17,4")와 원래 발생한 `underlyingError`를 확인할 수 있습니다.

## 동작 원리
1. **기기 식별자 조회:** `uname()` 또는 `sysctlbyname("hw.model")`을 사용하여 현재 기기의 식별자를 가져옵니다.
2. **기기 모델명 매핑:** GitHub 원격 저장소의(현재 방문중인 이 저장소)의 JSON 데이터를 참조하여 최신 기기 모델명 정보를 가져옵니다. JSON 파일은 DeviceName 폴더 내부에 OS별로 확인 가능합니다.

## 기여 방법

1. 이슈 또는 기능 요청은 `Issues` 탭에 작성해주세요.
2. PR은 언제나 환영합니다. 변경되었으면 하는 부분이나 새로운 기능들을 작업해주시면. 검토 후 버전에 추가하겠습니다.

> [!NOTE]
> 이 레포지토리의 업데이트가 느리거나, JSON을 직접 관리하고 싶을 경우, 레포지토리를 fork하여 직접 업데이트하세요.

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [`LICENSE`](LICENSE) 파일을 참고하세요.
