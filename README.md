# ヘルスケア書き出し / Health Export

iPhoneのヘルスケアに入っている記録を、**AIに渡せるテキスト**として書き出すアプリ。

期間と目的を選ぶだけで、必要な項目・まとめ方・AIへの依頼文がまとまって決まる。
書き出したテキストは、そのままチャット欄に貼るか、.txt ファイルとして共有できる。

- `com.zzzjjj080.HealthExport` / iOS 18.0以降 / iPhone / 日本語・英語
- 通信は一切しない。読み取ったデータは端末の中だけで扱う。

## 作り

| 場所 | 役割 |
|---|---|
| `prototype/index.html` | HTMLプロトタイプ。出力テキストの形はここで決めた |
| `HealthExportCore/` | UIにもHealthKitにも依存しないロジック層。`swift test` で回せる |
| `HealthExport/` | アプリ本体（SwiftUI + HealthKit） |
| `Tools-MakeIcon.swift` | アプリアイコンの生成 |
| `docs/` | サポートページとプライバシーポリシー（GitHub Pagesで公開） |

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

## リリース

- App ID `6806698295` / バンドルID `com.zzzjjj080.HealthExport`
- **1.0 (1) を 2026-09-02 に公開**（App Store: https://apps.apple.com/jp/app/id6806698295 ）
- 公開した 1.0 に投げ銭は入っていない。8/30にアップロードしたあとで実装したため。

### 1.1 で出すもの（未提出）

- 投げ銭「開発者にコーヒーを奢る」
  - **課金アイテムは `MISSING_METADATA`。** 情報を埋めないと審査に出せない
  - **最初の課金はアプリのバージョンと一緒に提出する必要がある**
  - 有料App契約・銀行口座・税務情報が先に要る（引き継ぎ書11節）
- 不具合の報告・要望を送るボタン
- バグ修正5件（気分のラベルの言語、生データの上限、エラーの蓄積、進捗表示、年をまたぐ期間の表示）
- 配信は日本のみ。無料。リリースは手動（承認されても自分のタイミングで出せる）
- サポートページ: https://zzzjjj080.github.io/healthexport/
- 掲載情報は App Store Connect API から入れている（`Tools-ASCToken.swift`）

### グローバル版でやること

アプリ本体は日英に対応済み（書き出すテキストの言語も選べる）。
足りないのは**ストア側**だけなので、次の3つを揃えれば配信地域を広げられる。
**配信地域の追加に審査は要らない。**

1. 英語の掲載情報（概要・キーワード・プロモーション文・サブタイトル）
   → `PATCH /v1/appStoreVersionLocalizations` で en-US を足す
2. **英語UIのスクリーンショット**。シミュレータの言語を英語にして撮り直す。
   `store/MakeScreenshots.swift` のキャプションも英語に差し替える

   ```bash
   xcrun simctl spawn booted defaults write -g AppleLanguages -array en
   ```
3. 配信地域にアメリカなどを足す（価格および配信状況の画面）

EU に広げるときだけ**トレーダーステータス（氏名・住所・電話の公開）**が要る。
日本と米国だけなら不要。

## そのほか残っていること

- 実機での長期運用の確認（数ヶ月ぶんの記録での書き出し速度）
