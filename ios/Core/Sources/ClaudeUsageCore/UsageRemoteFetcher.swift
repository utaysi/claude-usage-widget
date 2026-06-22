import Foundation

public enum UsageFetchOutcome: Equatable {
    case success(UsageSnapshot)
    case needsLogin
    case transient(String)
}

/// Cookie-based usage fetch for background refresh — no WebKit, so it runs when
/// the app is suspended. Reuses UsageHTTP.classify + UsageParser.parse.
public enum UsageRemoteFetcher {
    public static func buildUsageRequest(orgId: String,
                                         cookieHeader: String,
                                         userAgent: String) -> URLRequest {
        var req = URLRequest(url: URL(string: ClaudeAPI.base + ClaudeAPI.usagePath(org: orgId))!)
        req.httpMethod = "GET"
        req.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(ClaudeAPI.base + "/", forHTTPHeaderField: "Referer")
        return req
    }

    public static func fetchUsage(session: URLSession,
                                  orgId: String,
                                  cookieHeader: String,
                                  userAgent: String,
                                  now: Date) async -> UsageFetchOutcome {
        let req = buildUsageRequest(orgId: orgId, cookieHeader: cookieHeader, userAgent: userAgent)
        do {
            let (data, response) = try await session.data(for: req)
            let http = response as? HTTPURLResponse
            let status = http?.statusCode ?? 0
            let toLogin = http?.url?.path.contains("/login") ?? false
            let body = String(decoding: data, as: UTF8.self)
            switch UsageHTTP.classify(status: status, redirectedToLogin: toLogin, body: body) {
            case .needsLogin:
                return .needsLogin
            case .transient(let why):
                return .transient(why)
            case .success:
                do { return .success(try UsageParser.parse(data, now: now)) }
                catch { return .transient("parse") }
            }
        } catch {
            return .transient("io")
        }
    }
}
