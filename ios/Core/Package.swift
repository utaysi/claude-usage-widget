// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClaudeUsageCore",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(name: "ClaudeUsageCore", targets: ["ClaudeUsageCore"]),
    ],
    targets: [
        .target(name: "ClaudeUsageCore"),
        .testTarget(name: "ClaudeUsageCoreTests", dependencies: ["ClaudeUsageCore"]),
    ]
)
