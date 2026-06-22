import Foundation

public enum UsageLevel: Equatable, Sendable {
    case calm       // < 70
    case warn       // 70..<90
    case critical   // >= 90
    public init(utilization: Double) {
        switch utilization {
        case ..<70: self = .calm
        case ..<90: self = .warn
        default: self = .critical
        }
    }
}

public enum UsageFormat {
    public static func percent(_ utilization: Double) -> String {
        "\(Int(utilization.rounded()))%"
    }

    /// Short countdown like "2d 3h", "2h 14m", "45m", or "now" if already past.
    public static func countdown(to reset: Date, from now: Date) -> String {
        let secs = Int(reset.timeIntervalSince(now))
        if secs <= 0 { return "now" }
        let days = secs / 86400
        let hours = (secs % 86400) / 3600
        let mins = (secs % 3600) / 60
        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(mins)m" }
        return "\(mins)m"
    }
}
