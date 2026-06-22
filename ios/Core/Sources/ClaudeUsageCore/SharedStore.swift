import Foundation

public enum AuthState: String, Sendable {
    case unknown
    case ok
    case needsLogin = "needs_login"
}

/// Thin wrapper over a (shared App Group) UserDefaults. Provider-keyed. Injectable for tests.
public struct SharedStore {
    // Legacy (pre-provider) keys — kept for one-time migration.
    public static let snapshotKey = "usage.snapshot"
    public static let authStateKey = "usage.authState"
    public static let accentColorHexKey = "usage.accentColorHex"
    public static let orgIdKey = "usage.orgId"
    public static let accountIdKey = "usage.accountId"

    private let defaults: UserDefaults
    public init(defaults: UserDefaults) { self.defaults = defaults }

    /// Convenience for the real App Group; returns nil if entitlement is missing.
    public static func appGroup() -> SharedStore? {
        guard let d = UserDefaults(suiteName: AppConfig.appGroupID) else { return nil }
        return SharedStore(defaults: d)
    }

    private func snapKey(_ p: Provider) -> String { "usage.snapshot.\(p.rawValue)" }
    private func authKey(_ p: Provider) -> String { "usage.authState.\(p.rawValue)" }
    private func accentKey(_ p: Provider) -> String { "usage.accentColorHex.\(p.rawValue)" }

    public func saveSnapshot(_ snapshot: UsageSnapshot, for p: Provider) {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: snapKey(p))
        }
    }

    public func snapshot(for p: Provider) -> UsageSnapshot? {
        guard let data = defaults.data(forKey: snapKey(p)) else { return nil }
        return try? JSONDecoder().decode(UsageSnapshot.self, from: data)
    }

    public func authState(for p: Provider) -> AuthState {
        AuthState(rawValue: defaults.string(forKey: authKey(p)) ?? "") ?? .unknown
    }

    public func setAuthState(_ a: AuthState, for p: Provider) {
        defaults.set(a.rawValue, forKey: authKey(p))
    }

    public func accentColorHex(for p: Provider) -> String? {
        defaults.string(forKey: accentKey(p))
    }

    public func setAccentColorHex(_ hex: String?, for p: Provider) {
        defaults.set(hex, forKey: accentKey(p))
    }

    public var orgId: String? {
        get { defaults.string(forKey: Self.orgIdKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.orgIdKey) }
    }

    public var accountId: String? {
        get { defaults.string(forKey: Self.accountIdKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.accountIdKey) }
    }

    /// One-time copy of pre-provider global keys into the `.claude` slots.
    public func migrateLegacyKeysIfNeeded() {
        if defaults.data(forKey: snapKey(.claude)) == nil,
           let legacy = defaults.data(forKey: Self.snapshotKey) {
            defaults.set(legacy, forKey: snapKey(.claude))
        }
        if defaults.string(forKey: authKey(.claude)) == nil,
           let legacy = defaults.string(forKey: Self.authStateKey) {
            defaults.set(legacy, forKey: authKey(.claude))
        }
        if defaults.string(forKey: accentKey(.claude)) == nil,
           let legacy = defaults.string(forKey: Self.accentColorHexKey) {
            defaults.set(legacy, forKey: accentKey(.claude))
        }
    }
}
