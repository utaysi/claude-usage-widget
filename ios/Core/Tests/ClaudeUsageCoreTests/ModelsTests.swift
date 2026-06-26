import XCTest
@testable import ClaudeUsageCore

final class ModelsTests: XCTestCase {
    func testSnapshotCodableRoundTrip() throws {
        let snap = UsageSnapshot(
            fiveHour: UsageWindow(utilization: 62, resetsAt: Date(timeIntervalSince1970: 1_700_000_000)),
            sevenDay: UsageWindow(utilization: 38, resetsAt: Date(timeIntervalSince1970: 1_700_500_000)),
            fetchedAt: Date(timeIntervalSince1970: 1_699_999_000))
        let data = try JSONEncoder().encode(snap)
        let decoded = try JSONDecoder().decode(UsageSnapshot.self, from: data)
        XCTAssertEqual(decoded, snap)
    }

    func testConstantsUsagePath() {
        XCTAssertEqual(ClaudeAPI.usagePath(org: "abc"), "/api/organizations/abc/usage")
        XCTAssertEqual(ClaudeAPI.orgsPath, "/api/organizations")
        XCTAssertTrue(AppConfig.appGroupID.hasPrefix("group."))
    }
}
