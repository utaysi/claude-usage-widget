import Foundation
import ClaudeUsageCore

/// Fetches usage for a token-based provider: calls the usage API, and on 401/403
/// refreshes the token (persisting the rotated one) and retries once. Shared by
/// the foreground refresh and the background task — no WebView anywhere.
enum OAuthUsageClient {
    static func fetch(_ spec: ProviderSpec, session: URLSession = .shared, now: () -> Date = Date.init) async -> UsageFetchOutcome {
        guard let token = TokenStore.load(for: spec.provider) else { return .needsLogin }

        switch await call(spec, token: token, session: session, now: now()) {
        case .ok(let snap): return .success(snap)
        case .failed(let why): return .transient(why)
        case .unauthorized: break
        }

        guard !token.refreshToken.isEmpty,
              let refreshed = await refresh(spec, token: token, session: session) else { return .needsLogin }
        TokenStore.save(refreshed, for: spec.provider)

        switch await call(spec, token: refreshed, session: session, now: now()) {
        case .ok(let snap): return .success(snap)
        case .unauthorized: return .needsLogin
        case .failed(let why): return .transient(why)
        }
    }

    private enum CallResult { case ok(UsageSnapshot); case unauthorized; case failed(String) }

    private static func call(_ spec: ProviderSpec, token: OAuthToken, session: URLSession, now: Date) async -> CallResult {
        guard let (data, resp) = try? await session.data(for: spec.usageRequest(token)) else { return .failed("io") }
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 || status == 403 { return .unauthorized }
        guard status == 200, let snap = spec.parseUsage(data, now) else { return .failed("http-\(status)") }
        return .ok(snap)
    }

    private static func refresh(_ spec: ProviderSpec, token: OAuthToken, session: URLSession) async -> OAuthToken? {
        guard let (data, resp) = try? await session.data(for: spec.refreshRequest(token.refreshToken)),
              (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return spec.parseRefresh(data, token)
    }
}
