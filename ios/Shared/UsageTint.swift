import SwiftUI
import ClaudeUsageCore

enum UsageTint {
    static let defaultAccentHex = "#FF9500"

    /// Preset swatches offered in Settings (default orange first).
    static let presets = ["#FF9500", "#FF5A1F", "#34C759", "#0A84FF", "#AF52DE", "#FF375F"]

    /// The plain chosen accent color (no level logic).
    static func color(hex: String?) -> Color {
        Color(usageHex: hex ?? defaultAccentHex) ?? .orange
    }

    /// Accent color for a usage level: red once at/over the limit, else the chosen accent.
    static func resolve(utilization: Double, hex: String?) -> Color {
        if utilization >= 90 { return .red }
        return color(hex: hex)
    }
}

extension Color {
    init?(usageHex: String) {
        guard let c = HexColor.parse(usageHex) else { return nil }
        self = Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: 1)
    }

    /// Best-effort `#RRGGBB` for persisting a ColorPicker selection.
    func toHex() -> String? {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return HexColor.string(r: Double(r), g: Double(g), b: Double(b))
    }
}
