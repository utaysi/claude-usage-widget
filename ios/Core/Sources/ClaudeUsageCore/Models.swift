import Foundation

public struct UsageWindow: Codable, Equatable, Sendable {
    public var utilization: Double   // 0...100
    public var resetsAt: Date
    public init(utilization: Double, resetsAt: Date) {
        self.utilization = utilization
        self.resetsAt = resetsAt
    }
}

public struct UsageSnapshot: Codable, Equatable, Sendable {
    public var fiveHour: UsageWindow
    public var sevenDay: UsageWindow
    public var fetchedAt: Date
    public init(fiveHour: UsageWindow, sevenDay: UsageWindow, fetchedAt: Date) {
        self.fiveHour = fiveHour
        self.sevenDay = sevenDay
        self.fetchedAt = fetchedAt
    }
}
