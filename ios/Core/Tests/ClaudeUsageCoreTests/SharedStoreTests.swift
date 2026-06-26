import XCTest
@testable import ClaudeUsageCore

final class SharedStoreTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suite = "test." + UUID().uuidString
        return UserDefaults(suiteName: suite)!
    }

    func testSnapshotRoundTrip() {
        let defaults = makeDefaults()
        let store = SharedStore(defaults: defaults)
        XCTAssertNil(store.loadSnapshot())
        let snap = UsageSnapshot(
            fiveHour: UsageWindow(utilization: 62, resetsAt: Date(timeIntervalSince1970: 1_781_000_000)),
            sevenDay: UsageWindow(utilization: 38, resetsAt: Date(timeIntervalSince1970: 1_781_500_000)),
            fetchedAt: Date(timeIntervalSince1970: 1_780_900_000))
        store.saveSnapshot(snap)
        XCTAssertEqual(store.loadSnapshot(), snap)
    }

    func testOrgIdAndAuthState() {
        let store = SharedStore(defaults: makeDefaults())
        XCTAssertNil(store.orgId)
        store.orgId = "abc"
        store.authState = .ok
        XCTAssertEqual(store.orgId, "abc")
        XCTAssertEqual(store.authState, .ok)
    }

    func testAccentColorHexRoundTrip() {
        let store = SharedStore(defaults: makeDefaults())
        XCTAssertNil(store.accentColorHex)
        store.accentColorHex = "#FF9500"
        XCTAssertEqual(store.accentColorHex, "#FF9500")
    }
}
