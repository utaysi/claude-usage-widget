import Foundation

/// Claude Code OAuth credentials (from ~/.claude/.credentials.json), used to call
/// `api.anthropic.com/api/oauth/usage` and refreshed via console.anthropic.com.
public enum ClaudeAuth {
    /// Parse a pasted credential: `~/.claude/.credentials.json`
    /// (`{ "claudeAiOauth": { "accessToken", "refreshToken" } }`, any nesting) or
    /// a bare access token. No account id is needed for Claude.
    public static func parseCredentials(_ text: String) -> OAuthToken? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let data = trimmed.data(using: .utf8),
           let root = try? JSONSerialization.jsonObject(with: data),
           let access = JSONSearch.deepString(root, "accessToken"), !access.isEmpty {
            let refresh = JSONSearch.deepString(root, "refreshToken") ?? ""
            return OAuthToken(accessToken: access, refreshToken: refresh)
        }

        let bare = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\"', "))
        if bare.hasPrefix("sk-ant-"), bare.count > 20, !bare.contains(" ") {
            return OAuthToken(accessToken: bare, refreshToken: "")
        }
        return nil
    }

    /// Build the refresh-token request to `console.anthropic.com/v1/oauth/token`.
    public static func refreshRequest(refreshToken: String) -> URLRequest {
        var req = URLRequest(url: URL(string: AnthropicAPI.oauthTokenURL)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": AnthropicAPI.oauthClientID,
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return req
    }

    /// Parse the refresh response (`{access_token, refresh_token}`) into an updated token.
    public static func parseRefresh(_ data: Data, previous: OAuthToken) -> OAuthToken? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let access = obj["access_token"] as? String, !access.isEmpty else { return nil }
        let refresh = obj["refresh_token"] as? String ?? previous.refreshToken
        return OAuthToken(accessToken: access, refreshToken: refresh)
    }
}
