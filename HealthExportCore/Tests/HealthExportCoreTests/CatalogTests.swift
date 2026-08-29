import Foundation
import Testing
@testable import HealthExportCore

/// カタログの網羅と、IDの取り違えを防ぐためのテスト。
/// `MetricCatalog.metric(_:)` は `!` で取り出すので、抜けがあると実行時に落ちる。
struct CatalogTests {

    @Test func カタログはすべてのIDを網羅している() {
        for id in MetricID.allCases {
            #expect(MetricCatalog.all.contains { $0.id == id }, "\(id) がカタログに無い")
        }
        #expect(MetricCatalog.all.count == MetricID.allCases.count)
    }

    @Test func 短い列名は重複しない() {
        let keys = MetricCatalog.all.map(\.shortKey)
        #expect(Set(keys).count == keys.count)
    }

    @Test func 割合の項目は100倍の係数を持つ() {
        // HealthKit の % は 0〜1 で返る。ここを取り違えると 0.97% と書き出してしまう。
        for id in [MetricID.oxygenSaturation, .bodyFat, .walkingAsymmetry] {
            guard case .quantity(_, let unit, let scale) = MetricCatalog.metric(id).source else {
                Issue.record("\(id) が quantity ではない"); continue
            }
            #expect(unit == "%")
            #expect(scale == 100)
        }
    }

    @Test func 件数が多い項目だけ1件ずつの書き出しに対応する() {
        #expect(MetricCatalog.metric(.heartRate).supportsRawSamples)
        #expect(MetricCatalog.metric(.sleep).supportsRawSamples)
        // ワークアウトと気分は元から件数が少ない。1件ずつにする意味がない
        #expect(!MetricCatalog.metric(.workouts).supportsRawSamples)
        #expect(!MetricCatalog.metric(.stateOfMind).supportsRawSamples)
        // 1日1件しか出ないものも同じ
        #expect(!MetricCatalog.metric(.restingHeartRate).supportsRawSamples)
    }

    @Test func 目的が指す項目はすべて実在する() {
        for purpose in Purpose.allCases {
            for id in purpose.metricIDs ?? [] {
                #expect(MetricCatalog.all.contains { $0.id == id }, "\(purpose) が \(id) を指しているが無い")
            }
        }
    }

    @Test func 依頼文には必ず断りの一文が入る() {
        // 医療的な診断を求める文書ではないことを、どの目的でも明示しておく
        for purpose in Purpose.allCases {
            #expect(purpose.askText(.ja).contains("医療的な診断のためのものではありません"))
            #expect(purpose.askText(.en).contains("not for medical diagnosis"))
        }
    }
}
