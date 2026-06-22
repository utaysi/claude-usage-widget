import Foundation
import SwiftUI
import WidgetKit
import ClaudeUsageCore

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    let store: SharedStore
    let specs: [ProviderSpec] = ProviderSpec.all
    var providers: [Provider] { specs.map(\.provider) }

    @Published var snapshots: [Provider: UsageSnapshot] = [:]
    @Published var needsLogin: [Provider: Bool] = [:]
    @Published var accents: [Provider: String] = [:]
    @Published var lastError: [Provider: String] = [:]
    @Published var isRefreshing = false

    init() {
        let defaults = UserDefaults(suiteName: AppConfig.appGroupID)
        let store = SharedStore(defaults: defaults ?? .standard)
        store.migrateLegacyKeysIfNeeded()
        self.store = store

        for spec in specs {
            let p = spec.provider
            snapshots[p] = store.snapshot(for: p)
            accents[p] = store.accentColorHex(for: p) ?? spec.defaultAccentHex
            needsLogin[p] = TokenStore.load(for: p) == nil
        }
    }

    private func spec(_ p: Provider) -> ProviderSpec { ProviderSpec.spec(for: p) }

    func refresh(_ p: Provider) async {
        isRefreshing = true
        defer { isRefreshing = false }
        switch await OAuthUsageClient.fetch(spec(p)) {
        case .success(let s):
            snapshots[p] = s; needsLogin[p] = false; lastError[p] = nil
            store.saveSnapshot(s, for: p); store.setAuthState(.ok, for: p)
        case .needsLogin:
            needsLogin[p] = true; store.setAuthState(.needsLogin, for: p)
        case .transient(let why):
            lastError[p] = why
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    func refreshAll() async { for p in providers { await refresh(p) } }

    /// Store a pasted credential for a provider and refresh its usage.
    func setToken(_ p: Provider, fromPasted text: String) async -> Bool {
        guard let token = spec(p).parseToken(text) else { return false }
        TokenStore.save(token, for: p)
        needsLogin[p] = false
        await refresh(p)
        return true
    }

    func setAccent(_ hex: String, for p: Provider) {
        accents[p] = hex
        store.setAccentColorHex(hex, for: p)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func logout(_ p: Provider) {
        TokenStore.delete(for: p)
        snapshots[p] = nil
        needsLogin[p] = true
        store.setAuthState(.needsLogin, for: p)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
