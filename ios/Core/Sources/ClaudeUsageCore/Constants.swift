import Foundation

/// Anthropic OAuth usage API (token pasted from ~/.claude/.credentials.json).
public enum AnthropicAPI {
    public static let usageURL = "https://api.anthropic.com/api/oauth/usage"
    public static let oauthBeta = "oauth-2025-04-20"
    public static let oauthTokenURL = "https://console.anthropic.com/v1/oauth/token"
    public static let oauthClientID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
}

/// ChatGPT/Codex usage API (token pasted from ~/.codex/auth.json).
public enum ChatGPTAPI {
    public static let base = "https://chatgpt.com"
    public static let usagePath = "/backend-api/wham/usage"
    public static let oauthClientID = "app_EMoamEEZ73f0CkXaXp7hrann"
    public static let oauthTokenURL = "https://auth.openai.com/oauth/token"
}

public enum AppConfig {
    public static let appGroupID = "group.com.example.claudeusage"
    public static let bgRefreshTaskID = "com.example.claudeusage.refresh"
    public static let widgetKind = "ClaudeUsageWidget"
    public static let deepLinkURL = "claudeusage://refresh"
}
