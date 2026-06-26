import XCTest
@testable import ClaudeUsageCore

final class FetchClassificationTests: XCTestCase {
    func testSuccess() {
        XCTAssertEqual(UsageHTTP.classify(status: 200, redirectedToLogin: false, body: "{}"), .success)
    }
    func testUnauthorized() {
        XCTAssertEqual(UsageHTTP.classify(status: 401, redirectedToLogin: false, body: ""), .needsLogin)
    }
    func testRedirectToLogin() {
        XCTAssertEqual(UsageHTTP.classify(status: 200, redirectedToLogin: true, body: ""), .needsLogin)
    }
    func testCloudflareByStatus() {
        XCTAssertEqual(UsageHTTP.classify(status: 403, redirectedToLogin: false, body: ""), .transient("cloudflare"))
        XCTAssertEqual(UsageHTTP.classify(status: 503, redirectedToLogin: false, body: ""), .transient("cloudflare"))
    }
    func testCloudflareByBody() {
        XCTAssertEqual(UsageHTTP.classify(status: 200, redirectedToLogin: false, body: "Just a moment..."),
                       .success) // 200 wins; body marker only matters for non-200
        XCTAssertEqual(UsageHTTP.classify(status: 500, redirectedToLogin: false, body: "Just a moment..."),
                       .transient("cloudflare"))
    }
    func testOtherHTTP() {
        XCTAssertEqual(UsageHTTP.classify(status: 500, redirectedToLogin: false, body: ""), .transient("http-500"))
    }
}
