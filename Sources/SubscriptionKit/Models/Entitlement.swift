import Foundation

/// Represents an entitlement (access to a feature) for a customer
public struct Entitlement: Codable, Equatable, Sendable {

    /// Whether this entitlement is currently active
    public let isActive: Bool

    /// The product ID that grants this entitlement
    public let productId: String

    /// When this entitlement expires (nil for lifetime)
    public let expiresDate: Date?

    /// Whether the subscription will auto-renew
    public let willRenew: Bool

    /// The store where this was purchased
    public let store: Store?

    public init(
        isActive: Bool,
        productId: String,
        expiresDate: Date? = nil,
        willRenew: Bool = false,
        store: Store? = nil
    ) {
        self.isActive = isActive
        self.productId = productId
        self.expiresDate = expiresDate
        self.willRenew = willRenew
        self.store = store
    }

    /// Check if entitlement is expiring soon (within 7 days)
    public var isExpiringSoon: Bool {
        guard let expiresDate = expiresDate else { return false }
        let sevenDaysFromNow = Date().addingTimeInterval(7 * 24 * 60 * 60)
        return expiresDate < sevenDaysFromNow && expiresDate > Date()
    }

    /// Time remaining until expiration
    public var timeRemaining: TimeInterval? {
        guard let expiresDate = expiresDate else { return nil }
        return expiresDate.timeIntervalSinceNow
    }
}

/// Store where purchase was made
public enum Store: String, Codable, Sendable {
    case appStore = "APP_STORE"
    case playStore = "PLAY_STORE"
    case stripe = "STRIPE"
    case promotional = "PROMOTIONAL"
}
