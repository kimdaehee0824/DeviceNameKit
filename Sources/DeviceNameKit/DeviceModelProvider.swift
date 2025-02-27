import Foundation

/// 기기 모델 정보를 제공하는 프로토콜
protocol DeviceModelProvider {
    var jsonURL: URL { get }
    func fetchDeviceModels() async throws -> [String: String]
    func getDeviceIdentifier() -> String
}

/// 공통 JSON 다운로드 및 디코딩 기능을 제공하는 기본 구현
extension DeviceModelProvider {
    func fetchDeviceModels() async throws -> [String: String] {
        let (data, _) = try await URLSession.shared.data(from: jsonURL)
        return try JSONDecoder().decode([String: String].self, from: data)
    }
}

/// iOS(iPhone & iPad) 모델 정보를 가져오는 클래스
struct iOSModelProvider: DeviceModelProvider {
    let jsonURL = URL(string: "\(Constant.modelNamePath)iOS.json")!

    func getDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return convertMachineToString(&systemInfo)
    }
}

/// Apple Watch 모델 정보를 가져오는 클래스
struct AppleWatchModelProvider: DeviceModelProvider {
    let jsonURL = URL(string: "\(Constant.modelNamePath)watchOS.json")!

    func getDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return convertMachineToString(&systemInfo)
    }
}

/// macOS (Mac) 모델 정보를 가져오는 클래스
struct MacModelProvider: DeviceModelProvider {
    let jsonURL = URL(string: "\(Constant.modelNamePath)macOS.json")!

    func getDeviceIdentifier() -> String {
        var size: Int = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &machine, &size, nil, 0)
        return String(cString: machine)
    }
}

/// Apple TV (tvOS) 모델 정보를 가져오는 클래스
struct TVOSModelProvider: DeviceModelProvider {
    let jsonURL = URL(string: "\(Constant.modelNamePath)tvOS.json")!

    func getDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return convertMachineToString(&systemInfo)
    }
}

/// Apple Vision Pro (visionOS) 모델 정보를 가져오는 클래스
struct VisionOSModelProvider: DeviceModelProvider {
    let jsonURL = URL(string: "\(Constant.modelNamePath)visionOS.json")!

    func getDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return convertMachineToString(&systemInfo)
    }
}

/// 공통: `utsname` 구조체에서 machine 값을 변환하는 함수
private func convertMachineToString(_ machine: inout utsname) -> String {
    return withUnsafeBytes(of: &machine.machine) { rawBufferPointer in
        let pointer = rawBufferPointer.bindMemory(to: CChar.self).baseAddress!
        return String(cString: pointer)
    }
}
