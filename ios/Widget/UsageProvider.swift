import WidgetKit
import Foundation
import ClaudeUsageCore

struct UsageEntry: TimelineEntry {
    let date: Date
    let choice: ProviderChoice
    let claude: UsageSnapshot?
    let codex: UsageSnapshot?
    let claudeNeedsLogin: Bool
    let codexNeedsLogin: Bool
    let claudeAccent: String?
    let codexAccent: String?

    static let sample = UsageEntry(
        date: Date(), choice: .claude,
        claude: UsageSnapshot(
            fiveHour: UsageWindow(utilization: 62, resetsAt: Date(timeIntervalSinceNow: 2*3600+14*60)),
            sevenDay: UsageWindow(utilization: 38, resetsAt: Date(timeIntervalSinceNow: 4*86400)),
            fetchedAt: Date()),
        codex: UsageSnapshot(
            fiveHour: UsageWindow(utilization: 21, resetsAt: Date(timeIntervalSinceNow: 3*3600)),
            sevenDay: UsageWindow(utilization: 9, resetsAt: Date(timeIntervalSinceNow: 5*86400)),
            fetchedAt: Date()),
        claudeNeedsLogin: false, codexNeedsLogin: false,
        claudeAccent: nil, codexAccent: "#30D158")
}

struct UsageProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> UsageEntry { .sample }

    func snapshot(for configuration: ProviderSelectionIntent, in context: Context) async -> UsageEntry {
        context.isPreview ? .sample : currentEntry(configuration.provider)
    }

    func timeline(for configuration: ProviderSelectionIntent, in context: Context) async -> Timeline<UsageEntry> {
        Timeline(entries: [currentEntry(configuration.provider)],
                 policy: .after(Date(timeIntervalSinceNow: 15 * 60)))
    }

    private func currentEntry(_ choice: ProviderChoice) -> UsageEntry {
        let s = SharedStore.appGroup()
        return UsageEntry(
            date: Date(), choice: choice,
            claude: s?.snapshot(for: .claude),
            codex: s?.snapshot(for: .codex),
            claudeNeedsLogin: s?.authState(for: .claude) == .needsLogin,
            codexNeedsLogin: s?.authState(for: .codex) == .needsLogin,
            claudeAccent: s?.accentColorHex(for: .claude),
            codexAccent: s?.accentColorHex(for: .codex))
    }
}
