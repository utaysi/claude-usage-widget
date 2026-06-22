import XCTest
@testable import ClaudeUsageCore

final class ClaudeAuthTests: XCTestCase {
    func testParseCredentialsJSON() {
        let json = """
        { "claudeAiOauth": { "accessToken": "sk-ant-oat01-abc", "refreshToken": "sk-ant-ort01-xyz", "expiresAt": 1756162077244 } }
        """
        let t = ClaudeAuth.parseCredentials(json)
        XCTAssertEqual(t?.accessToken, "sk-ant-oat01-abc")
        XCTAssertEqual(t?.refreshToken, "sk-ant-ort01-xyz")
        XCTAssertNil(t?.accountId)
    }

    func testParseBareToken() {
        let t = ClaudeAuth.parseCredentials("  sk-ant-oat01-justthetoken-value-123  ")
        XCTAssertEqual(t?.accessToken, "sk-ant-oat01-justthetoken-value-123")
        XCTAssertEqual(t?.refreshToken, "")
    }

    func testParseRejectsGarbage() {
        XCTAssertNil(ClaudeAuth.parseCredentials("not json"))
        XCTAssertNil(ClaudeAuth.parseCredentials("{}"))
    }

    func testRefreshRequest() {
        let req = ClaudeAuth.refreshRequest(refreshToken: "r1")
        XCTAssertEqual(req.url?.absoluteString, "https://console.anthropic.com/v1/oauth/token")
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json")
        let body = try! JSONSerialization.jsonObject(with: req.httpBody!) as! [String: String]
        XCTAssertEqual(body["grant_type"], "refresh_token")
        XCTAssertEqual(body["refresh_token"], "r1")
        XCTAssertEqual(body["client_id"], "9d1c250a-e61b-44d9-88ed-5944d1962f5e")
    }

    func testParseRefreshRotates() {
        let prev = OAuthToken(accessToken: "old", refreshToken: "oldR")
        let t = ClaudeAuth.parseRefresh(Data(#"{"access_token":"newA","refresh_token":"newR","expires_in":3600}"#.utf8), previous: prev)
        XCTAssertEqual(t?.accessToken, "newA")
        XCTAssertEqual(t?.refreshToken, "newR")
    }

    func testUsageRequestHeaders() {
        let req = ClaudeUsageRequest.build(token: OAuthToken(accessToken: "tok", refreshToken: ""))
        XCTAssertEqual(req.url?.absoluteString, "https://api.anthropic.com/api/oauth/usage")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Authorization"), "Bearer tok")
        XCTAssertEqual(req.value(forHTTPHeaderField: "anthropic-beta"), "oauth-2025-04-20")
    }
}
