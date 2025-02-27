import Foundation

struct DeviceModelFetcher {
    private let provider: DeviceModelProvider
    private var deviceData: [String: String] = [:]

    init(provider: DeviceModelProvider) {
        self.provider = provider
    }

    /// JSON에서 모델 데이터를 불러오는 함수
    mutating func loadDeviceModels() async throws {
        self.deviceData = try await provider.fetchDeviceModels()
    }

    /// 현재 기기의 모델명을 반환
    func getDeviceModelName() -> String {
        let identifier = provider.getDeviceIdentifier()
        return deviceData[identifier] ?? identifier
    }
}
