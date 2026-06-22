import WidgetKit
import SwiftUI
import ClaudeUsageCore

@main
struct ClaudeUsageWidgetBundle: WidgetBundle {
    var body: some Widget { ClaudeUsageWidget() }
}

struct ClaudeUsageWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: AppConfig.widgetKind,
                               intent: ProviderSelectionIntent.self,
                               provider: UsageProvider()) { entry in
            UsageWidgetView(entry: entry)
        }
        .configurationDisplayName("Claude / Codex Usage")
        .description("Your 5-hour and weekly usage.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}
