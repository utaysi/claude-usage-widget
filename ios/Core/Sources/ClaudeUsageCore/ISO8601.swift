import Foundation

public enum ISO8601 {
    /// Parses an ISO-8601 timestamp, tolerating optional fractional seconds.
    public static func parse(_ s: String) -> Date? {
        if s.isEmpty { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFraction.date(from: s) { return d }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: s)
    }
}
