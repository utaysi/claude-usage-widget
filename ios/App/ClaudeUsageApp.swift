import SwiftUI
import ClaudeUsageCore

@main
struct ClaudeUsageApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = AppModel.shared

    init() {
        BackgroundRefresh.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                Task { await model.refresh() }
            case .background:
                BackgroundRefresh.schedule()
            default:
                break
            }
        }
    }
}
