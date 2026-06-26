import XCTest
@testable import ClaudeUsageCore

final class UsageFormatTests: XCTestCase {
    func testPercentRounds() {
        XCTAssertEqual(UsageFormat.percent(62.4), "62%")
        XCTAssertEqual(UsageFormat.percent(62.6), "63%")
    }
    func testCountdownDaysHoursMinutes() {
        let now = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(UsageFormat.countdown(to: Date(timeIntervalSince1970: 2 * 86400 + 3 * 3600), from: now), "2d 3h")
        XCTAssertEqual(UsageFormat.countdown(to: Date(timeIntervalSince1970: 2 * 3600 + 14 * 60), from: now), "2h 14m")
        XCTAssertEqual(UsageFormat.countdown(to: Date(timeIntervalSince1970: 45 * 60), from: now), "45m")
        XCTAssertEqual(UsageFormat.countdown(to: Date(timeIntervalSince1970: -10), from: now), "now")
    }
    func testLevelBuckets() {
        XCTAssertEqual(UsageLevel(utilization: 10), .calm)
        XCTAssertEqual(UsageLevel(utilization: 75), .warn)
        XCTAssertEqual(UsageLevel(utilization: 95), .critical)
    }
}
