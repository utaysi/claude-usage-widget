import WidgetKit
import Foundation
import ClaudeUsageCore

struct UsageEntry: TimelineEntry {
    let date: Date
    let snapshot: UsageSnapshot?
    let needsLogin: Bool
    let accentHex: String?

    static let sample = UsageEntry(
        date: Date(),
        snapshot: UsageSnapshot(
            fiveHour: UsageWindow(utilization: 62, resetsAt: Date(timeIntervalSinceNow: 2 * 3600 + 14 * 60)),
            sevenDay: UsageWindow(utilization: 38, resetsAt: Date(timeIntervalSinceNow: 4 * 86400)),
            fetchedAt: Date()),
        needsLogin: false,
        accentHex: nil)
}

struct UsageProvider: TimelineProvider {
    private func store() -> SharedStore? { SharedStore.appGroup() }

    func placeholder(in context: Context) -> UsageEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        completion(context.isPreview ? .sample : currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        let entry = currentEntry()
        let next = Date(timeIntervalSinceNow: 15 * 60)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> UsageEntry {
        let s = store()
        return UsageEntry(date: Date(),
                          snapshot: s?.loadSnapshot(),
                          needsLogin: s?.authState == .needsLogin,
                          accentHex: s?.accentColorHex)
    }
}
