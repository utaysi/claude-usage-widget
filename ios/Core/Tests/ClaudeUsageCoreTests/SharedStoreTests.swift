import XCTest
@testable import ClaudeUsageCore

final class SharedStoreTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "test." + UUID().uuidString)!
    }

    private func sampleSnap(_ u: Double) -> UsageSnapshot {
        UsageSnapshot(
            fiveHour: UsageWindow(utilization: u, resetsAt: Date(timeIntervalSince1970: 1_781_000_000)),
            sevenDay: UsageWindow(utilization: u / 2, resetsAt: Date(timeIntervalSince1970: 1_781_500_000)),
            fetchedAt: Date(timeIntervalSince1970: 1_780_900_000))
    }

    func testPerProviderSnapshotRoundTrip() {
        let store = SharedStore(defaults: makeDefaults())
        XCTAssertNil(store.snapshot(for: .claude))
        XCTAssertNil(store.snapshot(for: .codex))
        let c = sampleSnap(62), x = sampleSnap(40)
        store.saveSnapshot(c, for: .claude)
        store.saveSnapshot(x, for: .codex)
        XCTAssertEqual(store.snapshot(for: .claude), c)
        XCTAssertEqual(store.snapshot(for: .codex), x)
    }

    func testPerProviderAuthAndAccent() {
        let store = SharedStore(defaults: makeDefaults())
        XCTAssertEqual(store.authState(for: .codex), .unknown)
        store.setAuthState(.ok, for: .claude)
        store.setAuthState(.needsLogin, for: .codex)
        XCTAssertEqual(store.authState(for: .claude), .ok)
        XCTAssertEqual(store.authState(for: .codex), .needsLogin)
        store.setAccentColorHex("#FF9500", for: .claude)
        store.setAccentColorHex("#30D158", for: .codex)
        XCTAssertEqual(store.accentColorHex(for: .claude), "#FF9500")
        XCTAssertEqual(store.accentColorHex(for: .codex), "#30D158")
    }

    func testOrgAndAccountId() {
        let store = SharedStore(defaults: makeDefaults())
        store.orgId = "org-1"
        store.accountId = "acct-1"
        XCTAssertEqual(store.orgId, "org-1")
        XCTAssertEqual(store.accountId, "acct-1")
    }

    func testLegacyMigrationCopiesToClaude() {
        let defaults = makeDefaults()
        let store = SharedStore(defaults: defaults)
        let legacy = sampleSnap(70)
        defaults.set(try! JSONEncoder().encode(legacy), forKey: SharedStore.snapshotKey)
        defaults.set("ok", forKey: SharedStore.authStateKey)
        defaults.set("#AABBCC", forKey: SharedStore.accentColorHexKey)

        store.migrateLegacyKeysIfNeeded()

        XCTAssertEqual(store.snapshot(for: .claude), legacy)
        XCTAssertEqual(store.authState(for: .claude), .ok)
        XCTAssertEqual(store.accentColorHex(for: .claude), "#AABBCC")
    }
}
