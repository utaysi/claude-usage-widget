import WidgetKit
import SwiftUI
import ClaudeUsageCore

private struct ContainerBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) { content.containerBackground(for: .widget) { Color(.systemBackground) } }
        else { content }
    }
}

struct UsageWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: UsageEntry

    var body: some View {
        content.modifier(ContainerBackground()).widgetURL(URL(string: AppConfig.deepLinkURL))
    }

    private var showClaude: Bool { entry.choice == .claude || entry.choice == .both }
    private var showCodex: Bool { entry.choice == .codex || entry.choice == .both }

    @ViewBuilder private var content: some View {
        switch family {
        case .systemSmall:          smallView
        case .systemMedium:         mediumView
        case .accessoryRectangular: rectView
        case .accessoryCircular:    circularView
        default:                    smallView
        }
    }

    // MARK: home

    @ViewBuilder private var smallView: some View {
        if entry.choice == .both {
            VStack(alignment: .leading, spacing: 8) {
                if let c = entry.claude { ProviderLine(mark: "✳", label: "CLAUDE", snap: c, accent: entry.claudeAccent) }
                if let x = entry.codex  { ProviderLine(mark: "◆", label: "CODEX",  snap: x, accent: entry.codexAccent) }
            }.padding(12)
        } else if showClaude, let c = entry.claude {
            ProviderBlock(mark: "✳", label: "CLAUDE", snap: c, accent: entry.claudeAccent)
        } else if showCodex, let x = entry.codex {
            ProviderBlock(mark: "◆", label: "CODEX", snap: x, accent: entry.codexAccent)
        } else { NeedsLogin() }
    }

    @ViewBuilder private var mediumView: some View {
        HStack(spacing: 12) {
            if showClaude { mediumColumn(entry.claude, mark: "✳", label: "CLAUDE", accent: entry.claudeAccent) }
            if showClaude && showCodex { Divider() }
            if showCodex { mediumColumn(entry.codex, mark: "◆", label: "CODEX", accent: entry.codexAccent) }
        }.padding(14)
    }

    @ViewBuilder private func mediumColumn(_ snap: UsageSnapshot?, mark: String, label: String, accent: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            (Text("\(mark)\u{FE0E} ").foregroundColor(UsageTint.color(hex: accent)) + Text(label).foregroundColor(.secondary))
                .font(.caption2).bold()
            if let snap {
                Bar(title: "5H", window: snap.fiveHour, accent: accent)
                Bar(title: "1W", window: snap.sevenDay, accent: accent)
            } else { Text("Tap to log in").font(.caption2).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: lock screen

    @ViewBuilder private var rectView: some View {
        VStack(alignment: .leading, spacing: 2) {
            if entry.choice == .both {
                if let c = entry.claude { Text("Claude 5H \(UsageFormat.percent(c.fiveHour.utilization)) · 1W \(UsageFormat.percent(c.sevenDay.utilization))").font(.caption2) }
                if let x = entry.codex  { Text("Codex 5H \(UsageFormat.percent(x.fiveHour.utilization)) · 1W \(UsageFormat.percent(x.sevenDay.utilization))").font(.caption2) }
            } else if showCodex, let x = entry.codex {
                Text("Codex").font(.caption2).bold()
                Text("5H \(UsageFormat.percent(x.fiveHour.utilization)) · 1W \(UsageFormat.percent(x.sevenDay.utilization))").font(.caption)
            } else if let c = entry.claude {
                Text("Claude").font(.caption2).bold()
                Text("5H \(UsageFormat.percent(c.fiveHour.utilization)) · 1W \(UsageFormat.percent(c.sevenDay.utilization))").font(.caption)
            } else { Text("Tap to log in").font(.caption2) }
        }
    }

    @ViewBuilder private var circularView: some View {
        // A circle can't show two providers; "both" falls back to Claude's 5H.
        let snap = (showClaude ? entry.claude : nil) ?? entry.codex
        if let w = snap?.fiveHour {
            Gauge(value: min(w.utilization, 100), in: 0...100) { Text("5H") }
                currentValueLabel: { Text("\(Int(w.utilization.rounded()))") }
                .gaugeStyle(.accessoryCircularCapacity)
        } else { Image(systemName: "person.crop.circle.badge.exclamationmark") }
    }
}

// MARK: shared pieces

private struct NeedsLogin: View {
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
            Text("Tap to log in").font(.caption2)
        }
    }
}

private struct Bar: View {
    let title: String
    let window: UsageWindow
    let accent: String?
    private var color: Color { UsageTint.resolve(utilization: window.utilization, hex: accent) }
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title).font(.caption).bold()
                Spacer()
                Text(UsageFormat.percent(window.utilization)).font(.caption).bold().foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule().fill(color).frame(width: geo.size.width * min(window.utilization, 100) / 100)
                }
            }.frame(height: 6)
        }
    }
}

private struct ProviderBlock: View {
    let mark: String; let label: String; let snap: UsageSnapshot; let accent: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            (Text("\(mark)\u{FE0E} ").foregroundColor(UsageTint.color(hex: accent)) + Text(label).foregroundColor(.secondary))
                .font(.caption2).bold()
            Bar(title: "5H", window: snap.fiveHour, accent: accent)
            Bar(title: "1W", window: snap.sevenDay, accent: accent)
        }.padding(12)
    }
}

private struct ProviderLine: View {
    let mark: String; let label: String; let snap: UsageSnapshot; let accent: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            (Text("\(mark)\u{FE0E} ").foregroundColor(UsageTint.color(hex: accent)) + Text(label).foregroundColor(.secondary))
                .font(.caption2).bold()
            Text("5H \(UsageFormat.percent(snap.fiveHour.utilization)) · WK \(UsageFormat.percent(snap.sevenDay.utilization))")
                .font(.caption2).foregroundStyle(UsageTint.color(hex: accent))
        }
    }
}
