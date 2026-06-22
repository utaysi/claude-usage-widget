import XCTest
@testable import ClaudeUsageCore

final class ISO8601Tests: XCTestCase {
    func testParsesPlainInternetDateTime() {
        let d = ISO8601.parse("2026-06-21T18:00:00Z")
        XCTAssertNotNil(d)
        XCTAssertEqual(d!.timeIntervalSince1970, 1782064800, accuracy: 1)
    }
    func testParsesFractionalSeconds() {
        XCTAssertNotNil(ISO8601.parse("2026-06-21T18:00:00.123Z"))
    }
    func testEmptyAndGarbageReturnNil() {
        XCTAssertNil(ISO8601.parse(""))
        XCTAssertNil(ISO8601.parse("not-a-date"))
    }
}
