import Foundation
import ClaudeUsageCore

/// Everything provider-specific for the token-based usage flow. Both Claude and
/// Codex are pasted-token providers calling their own usage API.
struct ProviderSpec {
    let provider: Provider
    let displayName: String
    let defaultAccentHex: String
    /// Shown in the token-paste sheet.
    let tokenHint: String
    let parseToken: (String) -> OAuthToken?
    let usageRequest: (OAuthToken) -> URLRequest
    let parseUsage: (Data, Date) -> UsageSnapshot?
    let refreshRequest: (String) -> URLRequest
    let parseRefresh: (Data, OAuthToken) -> OAuthToken?

    static let claude = ProviderSpec(
        provider: .claude,
        displayName: "Claude",
        defaultAccentHex: "#FF9500",
        tokenHint: "On your Mac run  cat ~/.claude/.credentials.json  and paste the output here.",
        parseToken: ClaudeAuth.parseCredentials,
        usageRequest: ClaudeUsageRequest.build,
        parseUsage: { try? UsageParser.parse($0, now: $1) },
        refreshRequest: ClaudeAuth.refreshRequest,
        parseRefresh: ClaudeAuth.parseRefresh)

    static let codex = ProviderSpec(
        provider: .codex,
        displayName: "Codex",
        defaultAccentHex: "#30D158",
        tokenHint: "On your Mac run  cat ~/.codex/auth.json  and paste the output here.",
        parseToken: CodexAuth.parseAuthJSON,
        usageRequest: { CodexUsageRequest.build(accountId: $0.accountId ?? "", token: $0.accessToken) },
        parseUsage: { try? CodexUsageParser.parse($0, now: $1) },
        refreshRequest: CodexAuth.refreshRequest,
        parseRefresh: CodexAuth.parseRefresh)

    static let all: [ProviderSpec] = [.claude, .codex]
    static func spec(for p: Provider) -> ProviderSpec { p == .codex ? .codex : .claude }
}
