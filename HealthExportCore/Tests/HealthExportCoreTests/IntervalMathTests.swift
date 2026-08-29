import Foundation
import Testing
@testable import HealthExportCore

/// 睡眠が二重に数えられないことを固定する。
/// iPhoneとApple Watchが同じ夜を両方記録するのは普通に起きる。
struct IntervalMathTests {

    static let base = Date(timeIntervalSince1970: 1_780_000_000)
    static func at(_ minutes: Double) -> Date { base.addingTimeInterval(minutes * 60) }
    static func span(_ from: Double, _ to: Double) -> IntervalMath.Interval {
        IntervalMath.Interval(start: at(from), end: at(to))
    }

    @Test func 重ならない区間はそのまま足される() {
        #expect(IntervalMath.totalMinutes([Self.span(0, 60), Self.span(120, 150)]) == 90)
    }

    @Test func 完全に重なる区間は二重に数えない() {
        // 同じ夜をiPhoneとWatchが両方記録した場合
        #expect(IntervalMath.totalMinutes([Self.span(0, 480), Self.span(0, 480)]) == 480)
    }

    @Test func 部分的に重なる区間はつながって1つになる() {
        #expect(IntervalMath.totalMinutes([Self.span(0, 60), Self.span(30, 90)]) == 90)
        #expect(IntervalMath.merged([Self.span(0, 60), Self.span(30, 90)]).count == 1)
    }

    @Test func 内側にすっぽり入る区間は外側に吸収される() {
        #expect(IntervalMath.totalMinutes([Self.span(0, 100), Self.span(20, 40)]) == 100)
    }

    @Test func 端が接している区間はつながる() {
        #expect(IntervalMath.merged([Self.span(0, 60), Self.span(60, 120)]).count == 1)
        #expect(IntervalMath.totalMinutes([Self.span(0, 60), Self.span(60, 120)]) == 120)
    }

    @Test func 順番がばらばらでも正しくまとまる() {
        let intervals = [Self.span(120, 180), Self.span(0, 60), Self.span(30, 90)]
        #expect(IntervalMath.totalMinutes(intervals) == 150)
    }

    @Test func 長さが無い区間は数えない() {
        #expect(IntervalMath.totalMinutes([Self.span(60, 60)]) == 0)
    }

    @Test func 空のときは0になる() {
        #expect(IntervalMath.totalMinutes([]) == 0)
        #expect(IntervalMath.earliestStart([]) == nil)
    }

    @Test func 就寝と起床は全体の端を取る() {
        let intervals = [Self.span(30, 90), Self.span(0, 60), Self.span(120, 180)]
        #expect(IntervalMath.earliestStart(intervals) == Self.at(0))
        #expect(IntervalMath.latestEnd(intervals) == Self.at(180))
    }

    @Test func 逆に渡された区間も正しい向きに直る() {
        let interval = IntervalMath.Interval(start: Self.at(90), end: Self.at(30))
        #expect(interval.minutes == 60)
    }
}
