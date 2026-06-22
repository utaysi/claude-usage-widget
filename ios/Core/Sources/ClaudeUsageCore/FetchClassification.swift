import Foundation

public enum FetchClassification: Equatable, Sendable {
    case success
    case needsLogin
    case transient(String)
}

public enum UsageHTTP {
    /// Classifies a usage/orgs HTTP response into the app's fetch state machine.
    public static func classify(status: Int, redirectedToLogin: Bool, body: String) -> FetchClassification {
        if redirectedToLogin { return .needsLogin }
        switch status {
        case 200:
            return .success
        case 401:
            return .needsLogin
        case 403, 503:
            return .transient("cloudflare")
        default:
            if body.contains("Just a moment") { return .transient("cloudflare") }
            return .transient("http-\(status)")
        }
    }
}
