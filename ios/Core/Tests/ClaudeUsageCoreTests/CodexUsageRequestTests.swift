import XCTest
@testable import ClaudeUsageCore

final class CodexUsageRequestTests: XCTestCase {
    func testBuildHeadersAndURL() {
        let req = CodexUsageRequest.build(accountId: "acct-9", token: "tok-1")
        XCTAssertEqual(req.url?.absoluteString, "https://chatgpt.com/backend-api/wham/usage")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Authorization"), "Bearer tok-1")
        XCTAssertEqual(req.value(forHTTPHeaderField: "ChatGPT-Account-Id"), "acct-9")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Accept"), "application/json")
    }
}
