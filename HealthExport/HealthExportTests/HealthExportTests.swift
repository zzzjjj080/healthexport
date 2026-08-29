import Testing
@testable import HealthExport

/// ロジックのテストは HealthExportCore 側にある（`swift test` で速く回せる）。
/// ここはアプリ層だけを対象にする。
struct HealthExportTests {
    @Test func アプリがビルドできている() {
        #expect(true)
    }
}
