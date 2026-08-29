# ヘルスケア書き出し / Health Export

iPhoneのヘルスケアに入っている記録を、**AIに渡せるテキスト**として書き出すアプリ。

期間と目的を選ぶだけで、必要な項目・まとめ方・AIへの依頼文がまとまって決まる。
書き出したテキストは、そのままチャット欄に貼るか、.txt ファイルとして共有できる。

- `com.zzzjjj080.HealthExport` / iOS 18.0以降 / iPhone / 日本語・英語
- 通信は一切しない。読み取ったデータは端末の中だけで扱う。

## 作り

| 場所 | 役割 |
|---|---|
| `index.html` | HTMLプロトタイプ。出力テキストの形はここで決めた |
| `HealthExportCore/` | UIにもHealthKitにも依存しないロジック層。`swift test` で回せる |
| `HealthExport/` | アプリ本体（SwiftUI + HealthKit） |
| `Tools-MakeIcon.swift` | アプリアイコンの生成 |

### 設計で外せないところ

- **端末を申告させない。** 期間をスキャンして、記録がある項目だけを出す。
  持っている端末は「どの項目に記録があるか」に現れるので、聞く必要がない。
- **「0件」を「データが無い」と断定しない。** HealthKitは読み取りを拒否されていても
  クエリが成功して0件を返す。画面には必ず「許可がオフの可能性」も併記する。
- **デバイスで絞らない。** 歩数などはiPhoneとApple Watchが両方書き込む。
  ヘルスケアが重複を除いた値を使わないと、実際とは違う数字になる。
- **睡眠は区間をマージしてから数える。** 2台が同じ夜を記録すると2倍近くなる。
  （`IntervalMath`）
- **依頼文に「医療的な診断のためのものではありません」を必ず入れる。**

## 確認

```bash
cd HealthExportCore && swift test          # ロジック（速い）
cd HealthExport && xcodebuild -project HealthExport.xcodeproj -scheme HealthExport \
  -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

シミュレータには記録が無いので、デモの記録で動かす（`#if DEBUG` のみ）。

```bash
SIMCTL_CHILD_HEALTHEXPORT_DEMO=1 xcrun simctl launch booted com.zzzjjj080.HealthExport
```

## 残っていること

- Explicit App ID（`com.zzzjjj080.HealthExport`）の登録と HealthKit の有効化
- Xcode に Apple ID を追加（いまは `No Accounts` で実機ビルドが止まる）
- 実機での確認、ストア掲載情報、プライバシーポリシー
