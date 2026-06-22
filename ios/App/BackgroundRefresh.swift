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

    /// Cookie-based fetch (no WebKit). Keeps the last snapshot on a transient
    /// failure so a Cloudflare lapse never shows a false "tap to log in".
    private static func runFetch() async -> Bool {
        guard let store = SharedStore.appGroup(),
              let orgId = store.orgId,
              let creds = Keychain.loadCredentials() else { return false }

        let outcome = await UsageRemoteFetcher.fetchUsage(
            session: .shared, orgId: orgId,
            cookieHeader: creds.cookieHeader, userAgent: creds.userAgent, now: Date())

        switch outcome {
        case .success(let snap):
            store.saveSnapshot(snap)
            store.authState = .ok
            return true
        case .needsLogin:
            store.authState = .needsLogin
            return false
        case .transient:
            return false // keep last snapshot, leave authState untouched
        }
    }
}
