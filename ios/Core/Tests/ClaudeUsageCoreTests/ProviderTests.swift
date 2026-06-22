import XCTest
@testable import ClaudeUsageCore

final class ProviderTests: XCTestCase {
    func testRawValuesAndCases() {
        XCTAssertEqual(Provider.claude.rawValue, "claude")
        XCTAssertEqual(Provider.codex.rawValue, "codex")
        XCTAssertEqual(Provider.allCases, [.claude, .codex])
    }
}
