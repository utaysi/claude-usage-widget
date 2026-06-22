import Foundation
import BackgroundTasks
import WidgetKit
import ClaudeUsageCore

enum BackgroundRefresh {
    static let taskID = AppConfig.bgRefreshTaskID

    /// Call once, before the app finishes launching.
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            guard let refresh = task as? BGAppRefreshTask else { return }
            handle(refresh)
        }
    }

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGAppRefreshTask) {
        schedule() // chain the next one
        let work = Task {
            let ok = await runFetch()
            WidgetCenter.shared.reloadAllTimelines()
            task.setTaskCompleted(success: ok)
        }
        task.expirationHandler = { work.cancel() }
    }

    /// Token-based usage refresh for every provider that has a stored token.
    /// Transient failures keep the last snapshot.
    private static func runFetch() async -> Bool {
        guard let store = SharedStore.appGroup() else { return false }
        var anySuccess = false
        for spec in ProviderSpec.all {
            guard TokenStore.load(for: spec.provider) != nil else { continue }
            switch await OAuthUsageClient.fetch(spec) {
            case .success(let snap):
                store.saveSnapshot(snap, for: spec.provider)
                store.setAuthState(.ok, for: spec.provider)
                anySuccess = true
            case .needsLogin:
                store.setAuthState(.needsLogin, for: spec.provider)
            case .transient:
                break
            }
        }
        return anySuccess
    }
}
