import XCTest
@testable import ClaudeUsageCore

final class CodexAuthTests: XCTestCase {
    private func jwt(accountId: String) -> String {
        let payload = "{\"https://api.openai.com/auth\":{\"chatgpt_account_id\":\"\(accountId)\"}}"
        let b64 = Data(payload.utf8).base64EncodedString()
        return "header.\(b64).sig"
    }

    func testParseAuthJSONWithTokensWrapper() {
        let json = """
        { "tokens": { "access_token": "acc-tok", "refresh_token": "ref-tok", "account_id": "account-9" }, "last_refresh": "x" }
        """
        let t = CodexAuth.parseAuthJSON(json)
        XCTAssertEqual(t?.accessToken, "acc-tok")
        XCTAssertEqual(t?.refreshToken, "ref-tok")
        XCTAssertEqual(t?.accountId, "account-9")
    }

    func testParseAuthJSONFlat() {
        let t = CodexAuth.parseAuthJSON(#"{"access_token":"a","refresh_token":"r","account_id":"acc"}"#)
        XCTAssertEqual(t?.accessToken, "a")
        XCTAssertEqual(t?.accountId, "acc")
    }

    func testParseAuthJSONAccountFromIdToken() {
        let json = "{ \"tokens\": { \"access_token\": \"a\", \"id_token\": \"\(jwt(accountId: "acc-from-jwt"))\" } }"
        XCTAssertEqual(CodexAuth.parseAuthJSON(json)?.accountId, "acc-from-jwt")
    }

    func testParseAuthJSONRejectsGarbage() {
        XCTAssertNil(CodexAuth.parseAuthJSON("not json"))
        XCTAssertNil(CodexAuth.parseAuthJSON("{}"))
    }

    func testParseBareJWTToken() {
        let token = jwt(accountId: "acc-x")
        let t = CodexAuth.parseAuthJSON("  \(token)  ")
        XCTAssertEqual(t?.accessToken, token)
        XCTAssertEqual(t?.accountId, "acc-x")
        XCTAssertEqual(t?.refreshToken, "")
    }

    func testParseDeeplyNestedAuthJSON() {
        let json = """
        { "openai": { "session": { "access_token": "deep-acc", "refresh_token": "deep-ref", "account_id": "deep-id" } } }
        """
        let t = CodexAuth.parseAuthJSON(json)
        XCTAssertEqual(t?.accessToken, "deep-acc")
        XCTAssertEqual(t?.refreshToken, "deep-ref")
        XCTAssertEqual(t?.accountId, "deep-id")
    }

    func testAccountIdFromJWT() {
        XCTAssertEqual(CodexAuth.accountIdFromJWT(jwt(accountId: "acc-123")), "acc-123")
        XCTAssertNil(CodexAuth.accountIdFromJWT("nope"))
    }

    func testRefreshRequest() {
        let req = CodexAuth.refreshRequest(refreshToken: "ref-1")
        XCTAssertEqual(req.url?.absoluteString, "https://auth.openai.com/oauth/token")
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json")
        let body = try! JSONSerialization.jsonObject(with: req.httpBody!) as! [String: String]
        XCTAssertEqual(body["client_id"], "app_EMoamEEZ73f0CkXaXp7hrann")
        XCTAssertEqual(body["grant_type"], "refresh_token")
        XCTAssertEqual(body["refresh_token"], "ref-1")
    }

    func testParseRefreshRotatesAndKeepsAccount() {
        let prev = OAuthToken(accessToken: "old", refreshToken: "oldR", accountId: "acc")
        let t = CodexAuth.parseRefresh(Data(#"{"access_token":"newA","refresh_token":"newR"}"#.utf8), previous: prev)
        XCTAssertEqual(t?.accessToken, "newA")
        XCTAssertEqual(t?.refreshToken, "newR")
        XCTAssertEqual(t?.accountId, "acc")
    }
}
