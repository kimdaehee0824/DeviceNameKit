![Logo image](Asset/DeviceNameKit_banner.png)

DeviceNameKit은 iOS, macOS, watchOS, tvOS, visionOS에서 **기기 식별자(Device Identifier)를 상업용 모델명(Device Model Name)으로 변환**하는 경량 SDK입니다. SDK 업데이트 없이 최신 기기 정보를 유지할 수 있으며, 캐싱 기능을 지원하여 불필요한 서버 요청을 방지할 수 있습니다.

영어 문서를 보려면 [`여기를 클릭`](README.md)하세요. 

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

### 기본적인 기기 모델명 변환

```swift
import DeviceNameKit

let fetcher = DeviceNameFetcher(cachePolicy: .oneDay)

Task {
    let modelName = try await fetcher.getDeviceName()
    print("기기 모델명: \(modelName)") // 예: iPhone 15 Pro
}
```

### Completion Handler 방식

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

### Combine API 사용

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

### `preload()`를 활용한 사전 로드
클래스를 선언할 때. preload 함수를 사용하면 미리 서버와 통신해서 상업용 모델명을 가져올 수 있습니다. 

```swift
let fetcher = DeviceNameFetcher(cachePolicy: .threeDays)
fetcher.preload() // 앱 시작 시 미리 로드하여 성능 최적화
```

### `deviceModel` 속성으로 간편하게 접근
`preload()` 함수를 사용하고. 일정 시간 후 모델명을 String값으로 바로 접근할 수 있습니다.
서버 통신이 완려되지 않았거나 실패할 경우. `nil`을 반환합니다.

```swift
print("현재 기기 모델명: \(fetcher.deviceModel ?? "불명")")
```

## 동작 원리

1. **기기 식별자 조회**: `uname()` 또는 `sysctlbyname("hw.model")`을 사용하여 현재 기기의 식별자를 가져옵니다.
2. **기기 모델명 매핑**: github 원격 저장소의 JSON 데이터에서 최신 모델명 정보를 가져옵니다.
3. **캐싱 적용 (옵션)**: 기본적으로 최신 데이터를 가져오며, 필요하면 캐싱 기능을 사용하여 성능을 최적화합니다.

## 캐싱 정책

| 정책                      | 설명             |
| ----------------------- | -------------- |
| `.noCache`              | 항상 최신 데이터를 가져옴 |
| `.oneDay`               | 1일간 캐싱 유지      |
| `.threeDays`            | 3일간 캐싱 유지      |
| `.sevenDays`            | 7일간 캐싱 유지      |
| `.oneMonth`             | 1개월간 캐싱 유지     |
| `.custom(TimeInterval)` | 사용자 지정 기간      |

### 캐싱 적용 예시

```swift
let fetcher = DeviceNameFetcher(cachePolicy: .threeDays)
```

## 기여 방법

1. 이슈 또는 기능 요청은 `Issues` 탭을 활용해주세요.
2. 새로운 기능을 제안하고 싶다면 `Discussions`에 의견을 남겨주세요.
3. PR 기여 방법:
   - 저장소를 Fork합니다.
   - 새로운 브랜치를 생성합니다. (`feature/new-feature`)
   - 개발 후 PR을 요청합니다.

> [!NOTE]
> 이 레포지토리의 업데이트가 느릴 경우, 레포지토리를 fork하여 직접 업데이트하세요.

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [`LICENSE`](LICENSE) 파일을 참고하세요.
