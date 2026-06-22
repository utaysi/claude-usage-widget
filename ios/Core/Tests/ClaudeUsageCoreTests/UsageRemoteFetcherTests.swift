import XCTest
@testable import ClaudeUsageCore

/// Intercepts URLSession requests so fetchUsage can be tested without a network.
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var body = Data()
    nonisolated(unsafe) static var lastRequest: URLRequest?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        MockURLProtocol.lastRequest = request
        let resp = HTTPURLResponse(url: request.url!, statusCode: MockURLProtocol.status,
                                   httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: MockURLProtocol.body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

final class UsageRemoteFetcherTests: XCTestCase {
    private func session() -> URLSession {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: cfg)
    }

    func testBuildRequestSetsHeadersAndURL() {
        let req = UsageRemoteFetcher.buildUsageRequest(
            orgId: "org-1", cookieHeader: "a=b; c=d", userAgent: "UA/1.0")
        XCTAssertEqual(req.url?.absoluteString, "https://claude.ai/api/organizations/org-1/usage")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Cookie"), "a=b; c=d")
        XCTAssertEqual(req.value(forHTTPHeaderField: "User-Agent"), "UA/1.0")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func testFetchSuccessParsesSnapshot() async {
        MockURLProtocol.status = 200
        MockURLProtocol.body = Data("""
        {"five_hour":{"utilization":12.5,"resets_at":"2026-06-22T18:00:00Z"},
         "seven_day":{"utilization":20,"resets_at":"2026-06-28T00:00:00Z"}}
        """.utf8)
        let out = await UsageRemoteFetcher.fetchUsage(
            session: session(), orgId: "o", cookieHeader: "x=y", userAgent: "UA", now: Date())
        guard case .success(let snap) = out else { return XCTFail("expected success, got \(out)") }
        XCTAssertEqual(snap.fiveHour.utilization, 12.5, accuracy: 0.001)
    }

    func testFetch401IsNeedsLogin() async {
        MockURLProtocol.status = 401
        MockURLProtocol.body = Data()
        let out = await UsageRemoteFetcher.fetchUsage(
            session: session(), orgId: "o", cookieHeader: "x=y", userAgent: "UA", now: Date())
        XCTAssertEqual(out, .needsLogin)
    }

    func testFetch403IsTransientCloudflare() async {
        MockURLProtocol.status = 403
        MockURLProtocol.body = Data("Just a moment".utf8)
        let out = await UsageRemoteFetcher.fetchUsage(
            session: session(), orgId: "o", cookieHeader: "x=y", userAgent: "UA", now: Date())
        XCTAssertEqual(out, .transient("cloudflare"))
    }
}
