import XCTest

/// シートやシステムダイアログは、合成タップでは操作できない。（引き継ぎ書 4-24）
/// 画面の確認はここに書く。
final class HealthExportUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
}
