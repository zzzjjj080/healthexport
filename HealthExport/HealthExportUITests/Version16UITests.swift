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
