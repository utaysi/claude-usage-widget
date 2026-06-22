import Foundation

/// Result of a usage fetch.
public enum UsageFetchOutcome: Equatable {
    case success(UsageSnapshot)
    case needsLogin
    case transient(String)
}

/// A pasted OAuth credential (from a provider CLI's local creds file), used to
/// call the provider's usage API directly and refreshed when it expires.
public struct OAuthToken: Codable, Equatable, Sendable {
    public var accessToken: String
    public var refreshToken: String
    public var accountId: String?   // Codex only (ChatGPT-Account-Id); nil for Claude
    public init(accessToken: String, refreshToken: String, accountId: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accountId = accountId
    }
}

enum JSONSearch {
    /// Recursively find the first string value for `key` anywhere in a JSON object/array.
    static func deepString(_ obj: Any, _ key: String) -> String? {
        if let d = obj as? [String: Any] {
            if let v = d[key] as? String { return v }
            for (_, v) in d { if let r = deepString(v, key) { return r } }
        } else if let a = obj as? [Any] {
            for v in a { if let r = deepString(v, key) { return r } }
        }
        return nil
    }
}
