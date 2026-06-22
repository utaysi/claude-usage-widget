import Foundation

public enum ClaudeUsageRequest {
    /// GET api.anthropic.com/api/oauth/usage with the OAuth bearer token.
    public static func build(token: OAuthToken) -> URLRequest {
        var req = URLRequest(url: URL(string: AnthropicAPI.usageURL)!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue(AnthropicAPI.oauthBeta, forHTTPHeaderField: "anthropic-beta")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        return req
    }
}
