import Foundation

public enum AuthState: String, Sendable {
    case unknown
    case ok
    case needsLogin = "needs_login"
}

/// Thin wrapper over a (shared App Group) UserDefaults. Injectable for tests.
public struct SharedStore {
    public static let snapshotKey = "usage.snapshot"
    public static let orgIdKey = "usage.orgId"
    public static let authStateKey = "usage.authState"
    public static let accentColorHexKey = "usage.accentColorHex"

    private let defaults: UserDefaults
    public init(defaults: UserDefaults) { self.defaults = defaults }

    /// Convenience for the real App Group; returns nil if entitlement is missing.
    public static func appGroup() -> SharedStore? {
        guard let d = UserDefaults(suiteName: AppConfig.appGroupID) else { return nil }
        return SharedStore(defaults: d)
    }

    public func saveSnapshot(_ snapshot: UsageSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: Self.snapshotKey)
        }
    }

    public func loadSnapshot() -> UsageSnapshot? {
        guard let data = defaults.data(forKey: Self.snapshotKey) else { return nil }
        return try? JSONDecoder().decode(UsageSnapshot.self, from: data)
    }

    public var orgId: String? {
        get { defaults.string(forKey: Self.orgIdKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.orgIdKey) }
    }

    public var authState: AuthState {
        get { AuthState(rawValue: defaults.string(forKey: Self.authStateKey) ?? "") ?? .unknown }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Self.authStateKey) }
    }

    public var accentColorHex: String? {
        get { defaults.string(forKey: Self.accentColorHexKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.accentColorHexKey) }
    }
}
