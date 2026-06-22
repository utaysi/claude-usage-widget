import AppIntents
import WidgetKit

enum ProviderChoice: String, AppEnum {
    case claude, codex, both
    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Provider" }
    static var caseDisplayRepresentations: [ProviderChoice: DisplayRepresentation] {
        [.claude: "Claude", .codex: "Codex", .both: "Both"]
    }
}

struct ProviderSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Choose provider" }
    static var description: IntentDescription { "Show Claude, Codex, or both." }

    @Parameter(title: "Provider", default: .claude)
    var provider: ProviderChoice
}
