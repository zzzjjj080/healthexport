import XCTest

/// 投げ銭まわりの見た目。
///
/// **`.storekit` はスキームで指定している**（Coffee.storekit）。
/// `simctl launch` では効かないので、確認と審査用スクリーンショットはここから撮る。
/// （引き継ぎ書 11-9）
final class CoffeeTipUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    /// - Parameter shot: 起動と同時に開く画面（`settings` / `result`）。
    ///   詳しい設定はシートなので、たどって開くよりこちらが確実。
    private func launchApp(shot: String? = nil, arguments: [String] = []) -> XCUIApplication {
        // **バンドルIDを明示する。** 省くと、シミュレータに残っている別のアプリを
        // 掴んだまま素通りすることがある。他のアプリにも同じ識別子（buyCoffee）と
        // 同じ文言があるため、テストは通ってしまい、撮れたのは別アプリの画面だった。
        let app = XCUIApplication(bundleIdentifier: "com.zzzjjj080.HealthExport")
        app.launchEnvironment["HEALTHEXPORT_DEMO"] = "1"     // 記録のあるふり
        if let shot { app.launchEnvironment["HEALTHEXPORT_SHOT"] = shot }
        // 初回の説明を飛ばす。`-key value` は NSArgumentDomain として優先される
        app.launchArguments += ["-hasSeenIntro.v1", "YES"] + arguments
        app.launch()
        return app
    }

    /// 設定の「形式」タブを開いて、コーヒーの行が見えるところまで送る。
    private func openFormatTab(_ app: XCUIApplication) {
        XCTAssertTrue(app.buttons["形式"].waitForExistence(timeout: 15), "設定が開いていない")
        app.buttons["形式"].tap()
    }

    /// **このアプリを見ていることを毎回確かめる。**
    /// 識別子も文言も他のアプリと重なるので、アプリ固有のものを1つ必ず見る。
    private func assertIsThisApp(_ app: XCUIApplication) {
        XCTAssertTrue(
            app.staticTexts["ヘルスケア書き出し"].waitForExistence(timeout: 15)
                || app.staticTexts["書き出したもの"].waitForExistence(timeout: 3)
                || app.staticTexts["詳しい設定"].waitForExistence(timeout: 3),
            "別のアプリを見ている。バンドルIDと、シミュレータに残っているアプリを疑う")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// 設定の「形式」タブのいちばん下。**審査用スクリーンショットはこれを使う。**
    func testCoffeeCardInSettings() {
        let app = launchApp(shot: "settings")
        assertIsThisApp(app)
        openFormatTab(app)

        let coffee = app.buttons["buyCoffee"]
        for _ in 0..<6 where !coffee.exists {
            app.swipeUp()
        }
        XCTAssertTrue(coffee.waitForExistence(timeout: 10), "コーヒーの行が見つからない")
        XCTAssertTrue(coffee.isEnabled,
                      "ボタンが無効。商品が読めていない（.storekit のパスを疑う）")
        // 価格は StoreKit が返した文字列をそのまま出す。決め打ちしない。
        // シミュレータのストアフロントは米国なので $ 表記になる（11-9）
        XCTAssertTrue(coffee.label.contains("$") || coffee.label.contains("¥"),
                      "価格が出ていない。label=[\(coffee.label)]")
        XCTAssertTrue(app.staticTexts["このアプリが気に入ったら"].exists, "見出しが出ていない")

        attach(app, "coffee-settings")
    }

    /// 書き出した直後の控えめな1行。役に立った直後がいちばん自然な置き場所。
    func testCoffeeLinkOnResult() {
        let app = launchApp()
        assertIsThisApp(app)
        app.buttons["exportButton"].tap()

        let link = app.buttons["buyCoffeeCompact"]
        XCTAssertTrue(link.waitForExistence(timeout: 20), "書き出した画面に出ていない")
        XCTAssertTrue(link.isEnabled, "商品が読めていない")

        attach(app, "coffee-result")
    }

    /// 1杯目のお礼。杯数は UserDefaults なので起動引数で差し込める（11-10）。
    func testGratitudeAfterOneCup() {
        let app = launchApp(shot: "settings", arguments: ["-tipjar.cups", "1"])
        assertIsThisApp(app)
        openFormatTab(app)
        for _ in 0..<6 where !app.staticTexts["奢ってくれてありがとうございました"].exists {
            app.swipeUp()
        }
        XCTAssertTrue(
            app.staticTexts["奢ってくれてありがとうございました"].waitForExistence(timeout: 5),
            "1杯目のお礼が出ていない")
        attach(app, "coffee-thanks")
    }
}
