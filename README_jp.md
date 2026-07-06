![Logo image](Asset/DeviceNameKit_banner.png)

> You can view the document in different languages: [English](README.md), [한국어](README_ko.md), [日本語](README_jp.md)

**DeviceNameKit**は、Appleデバイスの**機種識別子（Device Identifier）を製品名（Device Model Name）に変換**するSDKです。iPhone、iPad、Mac、Apple Watch、Apple TV、Vision Proなど、すべてのAppleプラットフォームに対応しています。

このライブラリは、Apple内部の機種識別子（例: `iPhone15,2`）を分かりやすい製品名（例: `iPhone 14 Pro`）に変換します。マッピングデータはSDKに同梱されているため、**ほとんどのデバイスはネットワーク通信なしで即座に変換**されます。同梱データに存在しない新型デバイスのみリモートデータを参照するため、**アプリのアップデートなしで新機種に対応**できます。

- **ローカル優先の変換**: 同梱データによりオフラインでも動作
- **新機種への自動対応**: 同梱データにない機種のみリモートを参照し、アプリ更新なしで対応
- **一度解決すれば永久保存**: 成功した結果のみ保存し、以降ネットワーク通信は発生しません
- **async/await対応**: Swift Concurrencyによる直感的な非同期処理
- **Completion Handler対応**: 従来のコールバックパターンもそのまま利用可能
- **Combine API対応**: 購読時に実行されるリアクティブなデータフロー
- **安全な取得**: `getSafeDeviceName()`は失敗時にも機種識別子を返し、アプリの動作を維持

**デバイスごとの設定適用、ログ分析、A/Bテスト、カスタマーサポート対応**など、正確な機種名が必要なさまざまな場面で活用できます。

デモアプリは[こちら](https://github.com/kimdaehee0824/DeviceNameKit_Demo)からご確認いただけます。

## 2.0の変更点

v2.0.0では、データ取得の仕組みをローカル優先方式に全面刷新しました。**公開APIは変更されていないため、コードの修正なしでアップデートできます。**

- デバイスデータがSDKに同梱され、オフラインやネットワーク制限環境でも動作します。
- リモート参照は、同梱データに存在しない新型デバイスの場合のみ行われます。
- 解決に成功した名前のみ保存されます。まだマッピングが存在しない識別子は保存されず、データ更新後に自動で再試行されます。
- 1.xが保存したキャッシュは自動で移行されます。識別子がそのまま保存された不正なキャッシュは破棄され、正しく再解決されます。
- デフォルトのキャッシュポリシーが`.noCache`から`.forever`に変更されました。機種名は変わらないため、永久保存が適切なデフォルトです。
- シミュレータでは、ホストアーキテクチャ（`arm64`）ではなく、シミュレート中のデバイスの機種名を返します。

## 対応プラットフォーム

| OS       | 最低対応バージョン |
| -------- | -------- |
| iOS      | 13.0+    |
| macOS    | 11.0+    |
| watchOS  | 6.0+     |
| tvOS     | 13.0+    |
| visionOS | 1.0+     |

## インストール方法

### Swift Package Manager (SPM)

1. Xcodeで `File > Add Packages...` を選択します。
2. 次のURLを入力してパッケージを追加します。
   ```
   https://github.com/kimdaehee0824/DeviceNameKit.git
   ```
3. バージョンは`2.0.0`以上を選択し、`import DeviceNameKit` で利用できます。

## 使い方

### 1. 基本的な機種名変換 (`async/await`)
```swift
let fetcher = DeviceNameFetcher() // デフォルトポリシー: .forever

Task {
    do {
        let modelName = try await fetcher.getDeviceName()
        print("機種名: \(modelName)") // 例: iPhone 14 Pro
    } catch {
        print("エラー: \(error.localizedDescription)")
    }
}
```

### 2. Completion Handlerを使う
```swift
let fetcher = DeviceNameFetcher()

fetcher.getDeviceName { result in
    switch result {
    case .success(let modelName):
        print("機種名: \(modelName)")
    case .failure(let error):
        print("エラー: \(error.localizedDescription)")
    }
}
```

### 3. Combine APIを使う
```swift
import Combine

let fetcher = DeviceNameFetcher()

let cancellable = fetcher.getDeviceNamePublisher()
    .sink(receiveCompletion: { completion in
        if case .failure(let error) = completion {
            print("エラー: \(error)")
        }
    }, receiveValue: { modelName in
        print("機種名: \(modelName)")
    })
```

### 4. エラーを投げない関数 (`getSafeDeviceName`)
`getSafeDeviceName()`は、解決に失敗しても機種識別子を返すため、エラーハンドリングが不要な場合に適しています。

```swift
let fetcher = DeviceNameFetcher()

Task {
    let modelName = await fetcher.getSafeDeviceName()
    print("機種名: \(modelName)")
}
```
このメソッドは失敗時に元の機種識別子を返し、`os.log`で失敗ログを記録します。

### 5. `preload()`による事前ロード
`preload()`を呼び出すと、バックグラウンドで機種名を事前に解決します。アプリ起動時に呼んでおけば、実際に使う時点では値が準備されています。

```swift
let fetcher = DeviceNameFetcher()
fetcher.preload() // アプリ起動時に事前解決
```

### 6. `deviceModel`プロパティによる同期アクセス
保存された値または同梱データから、ネットワーク通信なしで機種名を直接取得します。同梱データにない新型デバイスがまだリモートで解決されていない場合のみ`nil`を返します。

```swift
print("現在の機種名: \(fetcher.deviceModel ?? "不明")")
```

## キャッシュポリシー

キャッシュポリシーは、**解決に成功した機種名をデバイスにどれだけ保存するか**を決めます。解決に失敗した識別子は、ポリシーに関係なく保存されません。

| ポリシー | 説明 |
|---|---|
| `.forever` (デフォルト) | 一度解決した名前を永久保存 — 推奨 |
| `.oneDay` | 1日間保存 |
| `.threeDays` | 3日間保存 |
| `.sevenDays` | 7日間保存 |
| `.oneMonth` | 1か月間保存 |
| `.custom(TimeInterval)` | カスタム期間 |
| `.noCache` | 保存せず毎回再解決（同梱データは常に優先利用） |

機種名はデバイスが変わらない限り変化しないため、デフォルトの`.forever`をそのまま使うことを推奨します。

```swift
let fetcher = DeviceNameFetcher(cachePolicy: .forever)
```

## エラーハンドリング
`DeviceNameFetcherError`列挙型で発生したエラーを確認できます。

```swift
public enum DeviceNameFetcherError: Error {
    case fetchFailed(deviceIdentifier: String, underlyingError: Error)
}
```
エラー発生時には、`deviceIdentifier`（例: `"iPhone15,2"`）と原因となった`underlyingError`を確認できます。このエラーは、ローカルデータにないデバイスのリモート参照が失敗した場合にのみ発生します。

## 動作の仕組み
1. **機種識別子の取得**: `uname()`または`sysctlbyname("hw.model")`で現在のデバイスの識別子を取得します。
2. **保存された値の確認**: 以前に解決に成功した名前がデバイスに保存されていれば、即座に返します。
3. **同梱データの参照**: SDKに含まれるJSONデータから識別子を検索します。ほとんどのデバイスはここで解決され、ネットワーク通信は発生しません。
4. **リモートデータの参照**: 同梱データにない新型デバイスの場合のみ、このリポジトリの`DeviceName`フォルダにある最新JSONを取得します。リモートデータにもまだ存在しない場合は識別子をそのまま返し、一定時間（1時間）後に再試行します。

解決に成功した名前のみ保存されるため、データ更新前の空白期間に誤った値が永久保存されることはありません。

## 1.xからのアップグレード

バージョンを上げるだけで、コードの修正は不要です。以下の動作変更にご注意ください。

- デフォルトのキャッシュポリシーが`.forever`になりました。以前のデフォルトを維持するには`DeviceNameFetcher(cachePolicy: .noCache)`と明示してください。
- 1.xが保存したキャッシュは初回実行時に自動移行されます。データ空白期間に識別子がそのまま保存されたキャッシュは破棄され、正しく再解決されます。
- 1.xクライアントのために、このリポジトリの`DeviceName/`フォルダとJSONスキーマは維持されます。

## コントリビューション

1. イシューや機能リクエストは`Issues`タブにお寄せください。
2. PRはいつでも歓迎します。レビューの上、次のバージョンに反映します。
3. デバイスデータを変更する場合は、`DeviceName/`フォルダのJSONを編集した後、`Scripts/sync-device-data.sh`を実行して同梱リソースを同期してください。2つの場所が一致しないとCIが失敗します。

> [!NOTE]
> このリポジトリの更新が遅い場合や、JSONを自分で管理したい場合は、リポジトリをforkしてご利用ください。`Constant.swift`の`modelNamePath`をforkしたリポジトリのURLに変更するだけです。

## ライセンス

このプロジェクトはMITライセンスの下で配布されています。詳細は[`LICENSE`](LICENSE)ファイルをご覧ください。
