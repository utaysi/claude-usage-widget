import Foundation

/// Pure hex ⇄ RGB helpers (no SwiftUI/UIKit) so logic stays host-testable.
public enum HexColor {
    /// Parses `#RRGGBB` or `RRGGBB`; returns 0...1 components, or nil if malformed.
    public static func parse(_ hex: String) -> (r: Double, g: Double, b: Double)? {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt32(s, radix: 16) else { return nil }
        return (Double((value >> 16) & 0xFF) / 255.0,
                Double((value >> 8) & 0xFF) / 255.0,
                Double(value & 0xFF) / 255.0)
    }

    /// Formats 0...1 components as `#RRGGBB` (uppercase).
    public static func string(r: Double, g: Double, b: Double) -> String {
        func byte(_ v: Double) -> Int { Int((min(max(v, 0), 1) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(r), byte(g), byte(b))
    }
}
