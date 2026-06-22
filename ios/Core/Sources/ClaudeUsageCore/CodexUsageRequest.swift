import Foundation

public enum CodexUsageRequest {
    public static func build(accountId: String, token: String) -> URLRequest {
        var req = URLRequest(url: URL(string: ChatGPTAPI.base + ChatGPTAPI.usagePath)!)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(accountId, forHTTPHeaderField: "ChatGPT-Account-Id")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(ChatGPTAPI.base + "/", forHTTPHeaderField: "Referer")
        return req
    }
}
