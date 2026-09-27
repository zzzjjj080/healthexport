import XCTest

/// 1.6 で足したもの：生理の記録（既定はオフ）と、週・月ごとのまとめ。
final class Version16UITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    /// 生理はオフ、表は1日ごと、から始める。設定はシミュレータに残るので、毎回ここで揃える。
    private func launchApp(shot: String) -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: "com.zzzjjj080.HealthExport")
        app.launchEnvironment["HEALTHEXPORT_DEMO"] = "1"
        app.launchEnvironment["HEALTHEXPORT_SHOT"] = shot
        app.launchEnvironment["HEALTHEXPORT_CYCLE"] = "0"
        app.launchEnvironment["HEALTHEXPORT_GROUPING"] = "day"
        app.launchArguments += ["-hasSeenIntro.v1", "YES"]
        app.launch()
        XCTAssertTrue(app.staticTexts["詳しい設定"].waitForExistence(timeout: 15),
                      "設定が開いていない（別のアプリを見ていないかも疑う）")
        return app
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// 既定ではオフで、項目の一覧にも「記録が無かった項目」にも生理は出ない。
    /// オンにすると、記録があれば項目として並ぶ。
    func testCycleIsOffByDefaultAndAppearsWhenTurnedOn() {
        let app = launchApp(shot: "settings")
        let toggle = app.switches["includeCycleToggle"]
        for _ in 0..<12 where !toggle.isHittable { app.swipeUp() }
        XCTAssertTrue(toggle.exists, "生理のスイッチが見つからない")
        XCTAssertEqual(toggle.value as? String, "0", "既定がオンになっている")
        XCTAssertFalse(app.staticTexts["生理"].exists, "オフなのに生理が項目に出ている")
        attach(app, "生理オフ")

        toggle.switches.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["生理"].waitForExistence(timeout: 10), "オンにしても項目に出ない")
        XCTAssertEqual(toggle.value as? String, "1")
        attach(app, "生理オン")

        toggle.switches.firstMatch.tap()   // 後のテストのために戻す
    }

    /// 「週ごと」を選んで書き出すと、週ごとの表になる。
    func testWeeklyGroupingChangesTheExport() {
        let app = launchApp(shot: "format")
        let weekly = app.buttons["週ごと"]
        XCTAssertTrue(weekly.waitForExistence(timeout: 10), "「表の1行」の切り替えが無い")
        weekly.tap()
        app.buttons["完了"].tap()

        let export = app.buttons["書き出す"]
        XCTAssertTrue(export.waitForExistence(timeout: 10))
        export.tap()
        let table = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "## 週ごとの記録")).firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 20), "週ごとの表になっていない")
        attach(app, "週ごとの書き出し")
    }
}

/// 画面の並びと、聞き方を変えると依頼文が入れ替わること（1.7）。
final class LayoutUITests: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: "com.zzzjjj080.HealthExport")
        app.launchEnvironment["HEALTHEXPORT_DEMO"] = "1"
        app.launchArguments += ["-hasSeenIntro.v1", "YES"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ヘルスケア書き出し"].waitForExistence(timeout: 15),
                      "別のアプリを見ている（バンドルIDを疑う）")
        return app
    }

    /// 聞き方を選び直すと、下の依頼文がその聞き方のものに入れ替わる。
    /// **ここが変わらないと、6つを選ぶ意味が画面から分からない。**
    func testAskTextFollowsThePurpose() {
        let app = launchApp()
        // 前回どれを選んだかは端末に残る。始める前にメインへ戻す
        XCTAssertTrue(app.buttons["purpose-general"].waitForExistence(timeout: 10))
        app.buttons["purpose-general"].tap()
        let ask = app.staticTexts["askText"]
        XCTAssertTrue(ask.waitForExistence(timeout: 10), "依頼文が出ていない")
        let general = ask.label
        XCTAssertTrue(general.contains("全体的な傾向"), "メインの依頼文が違う: \(general)")

        app.buttons["purpose-sleep"].tap()
        let sleep = app.staticTexts["askText"]
        XCTAssertTrue(sleep.waitForExistence(timeout: 5))
        XCTAssertNotEqual(sleep.label, general, "聞き方を変えても依頼文が同じ")
        XCTAssertTrue(sleep.label.contains("睡眠"), "睡眠の依頼文になっていない: \(sleep.label)")

        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "睡眠を選んだとき"; shot.lifetime = .keepAlways; add(shot)
    }

    /// どの聞き方でも項目数は変わらない（データは常に全部）。
    func testMetricCountDoesNotChangeWithPurpose() {
        let app = launchApp()
        let count = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", "項目")).firstMatch
        XCTAssertTrue(count.waitForExistence(timeout: 10), "項目数が出ていない")
        let before = count.label
        app.buttons["purpose-mind"].tap()
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", "項目")).firstMatch.label,
                       before, "聞き方を変えたら項目数が変わった")
    }
}
