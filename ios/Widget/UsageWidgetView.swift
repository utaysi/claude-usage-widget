import WidgetKit
import SwiftUI
import ClaudeUsageCore

/// Applies the iOS 17+ required container background; no-op on iOS 16.
private struct ContainerBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.containerBackground(for: .widget) { Color(.systemBackground) }
        } else {
            content
        }
    }
}

struct UsageWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: UsageEntry

    var body: some View {
        content
            .modifier(ContainerBackground())
            .widgetURL(URL(string: AppConfig.deepLinkURL))
    }

    @ViewBuilder private var content: some View {
        if entry.needsLogin {
            NeedsLoginView(family: family)
        } else if let snap = entry.snapshot {
            switch family {
            case .systemSmall:          SmallView(snapshot: snap, accentHex: entry.accentHex)
            case .systemMedium:         MediumView(snapshot: snap, accentHex: entry.accentHex)
            case .accessoryRectangular: RectView(snapshot: snap)
            case .accessoryCircular:    CircularView(window: snap.fiveHour)
            default:                    SmallView(snapshot: snap, accentHex: entry.accentHex)
            }
        } else {
            Text("—").font(.headline).foregroundStyle(.secondary)
        }
    }
}

private struct NeedsLoginView: View {
    let family: WidgetFamily
    var body: some View {
        if family == .accessoryCircular {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
        } else {
            VStack(spacing: 2) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                Text("Tap to log in").font(.caption2)
            }
        }
    }
}

// MARK: - Home screen

private struct BarRow: View {
    let title: String
    let window: UsageWindow
    let accentHex: String?
    private var color: Color { UsageTint.resolve(utilization: window.utilization, hex: accentHex) }
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title).font(.caption).bold()
                Spacer()
                Text(UsageFormat.percent(window.utilization))
                    .font(.caption).bold().foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule().fill(color)
                        .frame(width: geo.size.width * min(window.utilization, 100) / 100)
                }
            }
            .frame(height: 6)
        }
    }
}

private struct SmallView: View {
    let snapshot: UsageSnapshot
    let accentHex: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            (Text("\u{2733}\u{FE0E} ").foregroundColor(UsageTint.color(hex: accentHex))
                + Text("CLAUDE").foregroundColor(.secondary))
                .font(.caption2).bold()
            BarRow(title: "5H", window: snapshot.fiveHour, accentHex: accentHex)
            BarRow(title: "1W", window: snapshot.sevenDay, accentHex: accentHex)
        }
        .padding(12)
    }
}

private struct MediumRow: View {
    let title: String
    let window: UsageWindow
    let accentHex: String?
    private var color: Color { UsageTint.resolve(utilization: window.utilization, hex: accentHex) }
    var body: some View {
        HStack(spacing: 8) {
            Text(title).font(.caption).bold().frame(width: 26, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule().fill(color)
                        .frame(width: geo.size.width * min(window.utilization, 100) / 100)
                }
            }
            .frame(height: 8)
            Text(UsageFormat.percent(window.utilization))
                .font(.caption).bold().frame(width: 42, alignment: .trailing)
                .foregroundStyle(color)
            Text("resets \(window.resetsAt, style: .relative)")
                .font(.caption2).foregroundStyle(.secondary)
                .frame(width: 92, alignment: .leading)
        }
    }
}

private struct MediumView: View {
    let snapshot: UsageSnapshot
    let accentHex: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                (Text("\u{2733}\u{FE0E} ").foregroundColor(UsageTint.color(hex: accentHex))
                    + Text("CLAUDE USAGE").foregroundColor(.secondary))
                    .font(.caption2).bold()
                Spacer()
                Text("\(snapshot.fetchedAt, style: .relative) ago")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            MediumRow(title: "5H", window: snapshot.fiveHour, accentHex: accentHex)
            MediumRow(title: "1W", window: snapshot.sevenDay, accentHex: accentHex)
        }
        .padding(14)
    }
}

// MARK: - Lock screen

private struct RectView: View {
    let snapshot: UsageSnapshot
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Claude").font(.caption2).bold()
            Text("5H \(UsageFormat.percent(snapshot.fiveHour.utilization)) · 1W \(UsageFormat.percent(snapshot.sevenDay.utilization))")
                .font(.caption)
            Text("5H resets \(snapshot.fiveHour.resetsAt, style: .relative)")
                .font(.caption2).foregroundStyle(.secondary)
        }
    }
}

private struct CircularView: View {
    let window: UsageWindow
    var body: some View {
        Gauge(value: min(window.utilization, 100), in: 0...100) {
            Text("5H")
        } currentValueLabel: {
            Text("\(Int(window.utilization.rounded()))")
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}
