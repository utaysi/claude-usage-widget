import Foundation

public enum OrgSelector {
    /// Picks an org id from the GET /api/organizations array body.
    /// Prefers an org whose capabilities include "chat" or "claude_ai".
    public static func selectOrgId(from body: Data) -> String? {
        guard let arr = try? JSONSerialization.jsonObject(with: body) as? [[String: Any]],
              !arr.isEmpty else { return nil }
        for org in arr {
            let caps = (org["capabilities"] as? [Any])?.compactMap { $0 as? String } ?? []
            let isChat = caps.contains {
                let l = $0.lowercased()
                return l.contains("chat") || l.contains("claude_ai")
            }
            if isChat, let id = id(of: org) { return id }
        }
        return id(of: arr[0])
    }

    private static func id(of org: [String: Any]) -> String? {
        if let uuid = org["uuid"] as? String, !uuid.isEmpty { return uuid }
        if let id = org["id"] as? String, !id.isEmpty { return id }
        return nil
    }
}
