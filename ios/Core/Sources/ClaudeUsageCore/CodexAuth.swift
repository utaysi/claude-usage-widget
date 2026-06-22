import Foundation

/// Codex CLI OAuth credentials (from ~/.codex/auth.json), used to call the real
/// `/backend-api/wham/usage` API — the only Codex-usage surface a third-party app
/// can authenticate against.
public enum CodexAuth {
    /// Parse a pasted credential: full `~/.codex/auth.json` (any nesting), or a
    /// bare access-token JWT. Deep-searches for the token fields so it tolerates
    /// format variations.
    public static func parseAuthJSON(_ text: String) -> OAuthToken? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let data = trimmed.data(using: .utf8),
           let root = try? JSONSerialization.jsonObject(with: data),
           let access = JSONSearch.deepString(root, "access_token"), !access.isEmpty {
            let refresh = JSONSearch.deepString(root, "refresh_token") ?? ""
            var account = JSONSearch.deepString(root, "account_id") ?? ""
            if account.isEmpty {
                account = accountIdFromJWT(JSONSearch.deepString(root, "id_token") ?? access) ?? ""
            }
            return OAuthToken(accessToken: access, refreshToken: refresh, accountId: account)
        }

        // Bare access-token JWT (no refresh token; valid until expiry).
        let bare = trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "\"', "))
        if bare.split(separator: ".").count >= 2, bare.count > 40, !bare.contains(" ") {
            return OAuthToken(accessToken: bare, refreshToken: "", accountId: accountIdFromJWT(bare) ?? "")
        }
        return nil
    }

    /// Extract `chatgpt_account_id` from a JWT's `https://api.openai.com/auth` claim.
    public static func accountIdFromJWT(_ jwt: String) -> String? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var b64 = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while b64.count % 4 != 0 { b64 += "=" }
        guard let data = Data(base64Encoded: b64),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let auth = obj["https://api.openai.com/auth"] as? [String: Any],
              let id = auth["chatgpt_account_id"] as? String else { return nil }
        return id
    }

    /// Build the refresh-token request to `auth.openai.com/oauth/token`.
    public static func refreshRequest(refreshToken: String) -> URLRequest {
        var req = URLRequest(url: URL(string: ChatGPTAPI.oauthTokenURL)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "client_id": ChatGPTAPI.oauthClientID,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "scope": "openid profile email",
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return req
    }

    /// Parse the refresh response into an updated token (the refresh token may rotate).
    public static func parseRefresh(_ data: Data, previous: OAuthToken) -> OAuthToken? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let access = obj["access_token"] as? String, !access.isEmpty else { return nil }
        let refresh = obj["refresh_token"] as? String ?? previous.refreshToken
        var account = previous.accountId ?? ""
        if account.isEmpty, let idTok = obj["id_token"] as? String {
            account = accountIdFromJWT(idTok) ?? ""
        }
        return OAuthToken(accessToken: access, refreshToken: refresh, accountId: account)
    }
}
