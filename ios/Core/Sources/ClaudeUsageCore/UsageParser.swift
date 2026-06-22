import Foundation

public enum UsageParseError: Error, Equatable {
    case invalidJSON
    case missingWindow(String)
}

public enum UsageParser {
    /// Parses the body of GET /api/organizations/{org}/usage.
    public static func parse(_ body: Data, now: Date) throws -> UsageSnapshot {
        guard let root = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            throw UsageParseError.invalidJSON
        }
        return UsageSnapshot(
            fiveHour: try window(in: root, key: "five_hour"),
            sevenDay: try window(in: root, key: "seven_day"),
            fetchedAt: now)
    }

    private static func window(in root: [String: Any], key: String) throws -> UsageWindow {
        guard let obj = root[key] as? [String: Any] else {
            throw UsageParseError.missingWindow(key)
        }
        let util = (obj["utilization"] as? NSNumber)?.doubleValue ?? 0
        let reset = ISO8601.parse(obj["resets_at"] as? String ?? "") ?? Date(timeIntervalSince1970: 0)
        return UsageWindow(utilization: util, resetsAt: reset)
    }
}
