import XCTest
@testable import ClaudeUsageCore

final class UsageParserTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_781_000_000)

    func testParsesBothWindows() throws {
        let json = """
        {"five_hour":{"utilization":62.5,"resets_at":"2026-06-21T18:00:00Z"},
         "seven_day":{"utilization":38,"resets_at":"2026-06-25T09:00:00Z"}}
        """.data(using: .utf8)!
        let snap = try UsageParser.parse(json, now: now)
        XCTAssertEqual(snap.fiveHour.utilization, 62.5, accuracy: 0.001)
        XCTAssertEqual(snap.sevenDay.utilization, 38, accuracy: 0.001)
        XCTAssertEqual(snap.fiveHour.resetsAt.timeIntervalSince1970, 1782064800, accuracy: 1)
        XCTAssertEqual(snap.fetchedAt, now)
    }

    func testMissingUtilizationDefaultsToZero() throws {
        let json = """
        {"five_hour":{"resets_at":"2026-06-21T18:00:00Z"},
         "seven_day":{"utilization":10,"resets_at":"2026-06-25T09:00:00Z"}}
        """.data(using: .utf8)!
        let snap = try UsageParser.parse(json, now: now)
        XCTAssertEqual(snap.fiveHour.utilization, 0)
    }

    func testMissingWindowThrows() {
        let json = #"{"five_hour":{"utilization":1,"resets_at":"2026-06-21T18:00:00Z"}}"#.data(using: .utf8)!
        XCTAssertThrowsError(try UsageParser.parse(json, now: now))
    }

    func testInvalidJSONThrows() {
        XCTAssertThrowsError(try UsageParser.parse(Data("nope".utf8), now: now))
    }
}
