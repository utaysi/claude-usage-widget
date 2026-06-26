import XCTest
@testable import ClaudeUsageCore

final class HexColorTests: XCTestCase {
    func testParseWithHash() {
        let c = HexColor.parse("#FF9500")
        XCTAssertEqual(c?.r ?? -1, 1.0, accuracy: 0.001)
        XCTAssertEqual(c?.g ?? -1, 0.584, accuracy: 0.01)
        XCTAssertEqual(c?.b ?? -1, 0.0, accuracy: 0.001)
    }

    func testParseWithoutHash() {
        XCTAssertNotNil(HexColor.parse("00FF00"))
    }

    func testParseRejectsGarbage() {
        XCTAssertNil(HexColor.parse("nope"))
        XCTAssertNil(HexColor.parse("#FFF"))
    }

    func testRoundTrip() {
        XCTAssertEqual(HexColor.string(r: 1, g: 0.584, b: 0), "#FF9500")
    }
}
