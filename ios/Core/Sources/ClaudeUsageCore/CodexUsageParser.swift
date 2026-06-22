import Foundation

/// Parses GET /backend-api/wham/usage (Codex rate limits) into a UsageSnapshot.
/// primary_window -> 5h, secondary_window -> weekly. reset_at is epoch seconds.
public enum CodexUsageParser {
    public static func parse(_ body: Data, now: Date) throws -> UsageSnapshot {
        guard let root = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let rl = root["rate_limit"] as? [String: Any] else {
            throw UsageParseError.invalidJSON
        }
        return UsageSnapshot(
            fiveHour: try window(in: rl, key: "primary_window"),
            sevenDay: try window(in: rl, key: "secondary_window"),
            fetchedAt: now)
    }

    private static func window(in rl: [String: Any], key: String) throws -> UsageWindow {
        guard let obj = rl[key] as? [String: Any] else { throw UsageParseError.missingWindow(key) }
        let util = (obj["used_percent"] as? NSNumber)?.doubleValue ?? 0
        let reset: Date
        if let epoch = (obj["reset_at"] as? NSNumber)?.doubleValue {
            reset = Date(timeIntervalSince1970: epoch)
        } else {
            reset = Date(timeIntervalSince1970: 0)
        }
        return UsageWindow(utilization: util, resetsAt: reset)
    }
}
