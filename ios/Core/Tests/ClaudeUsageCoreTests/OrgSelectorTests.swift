import XCTest
@testable import ClaudeUsageCore

final class OrgSelectorTests: XCTestCase {
    func testPrefersChatCapableOrg() {
        let json = """
        [{"uuid":"a","capabilities":["api"]},
         {"uuid":"b","capabilities":["chat","claude_ai"]}]
        """.data(using: .utf8)!
        XCTAssertEqual(OrgSelector.selectOrgId(from: json), "b")
    }
    func testFallsBackToFirstWhenNoChatCapability() {
        let json = #"[{"uuid":"a","capabilities":["api"]}]"#.data(using: .utf8)!
        XCTAssertEqual(OrgSelector.selectOrgId(from: json), "a")
    }
    func testFallsBackToIdWhenNoUuid() {
        let json = #"[{"id":"x","capabilities":["chat"]}]"#.data(using: .utf8)!
        XCTAssertEqual(OrgSelector.selectOrgId(from: json), "x")
    }
    func testEmptyArrayReturnsNil() {
        XCTAssertNil(OrgSelector.selectOrgId(from: Data("[]".utf8)))
    }
    func testInvalidReturnsNil() {
        XCTAssertNil(OrgSelector.selectOrgId(from: Data("{}".utf8)))
    }
}
