import XCTest
@testable import ClaudeUsageCore

final class CodexUsageParserTests: XCTestCase {
    func testParsesPrimaryAndSecondaryWindows() throws {
        // primary=5h, secondary=weekly; reset_at is epoch seconds.
        let body = Data("""
        {"rate_limit":{
          "primary_window":{"used_percent":17.5,"reset_at":1782064800},
          "secondary_window":{"used_percent":8,"reset_at":1782583200}},
          "plan_type":"pro"}
        """.utf8)
        let snap = try CodexUsageParser.parse(body, now: Date(timeIntervalSince1970: 1_782_000_000))
        XCTAssertEqual(snap.fiveHour.utilization, 17.5, accuracy: 0.001)
        XCTAssertEqual(snap.sevenDay.utilization, 8, accuracy: 0.001)
        XCTAssertEqual(snap.fiveHour.resetsAt, Date(timeIntervalSince1970: 1782064800))
        XCTAssertEqual(snap.sevenDay.resetsAt, Date(timeIntervalSince1970: 1782583200))
    }

    func testMissingRateLimitThrows() {
        XCTAssertThrowsError(try CodexUsageParser.parse(Data("{}".utf8), now: Date()))
    }

    func testMalformedThrows() {
        XCTAssertThrowsError(try CodexUsageParser.parse(Data("not json".utf8), now: Date()))
    }
}
