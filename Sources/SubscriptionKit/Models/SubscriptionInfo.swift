import Foundation

/// Detailed information about a subscription
public struct SubscriptionInfo: Codable, Equatable, Sendable {

    /// The product identifier
    public let productId: String

    /// Current status of the subscription
    public let status: SubscriptionStatus

    /// Store where purchased
    public let store: Store

    /// Original purchase date
    public let purchaseDate: Date?

    /// Current period expiration date
    public let expiresDate: Date?

    /// Whether auto-renew is enabled
    public let willRenew: Bool

    /// Price paid for current period
    public let price: Decimal?

    /// Currency code
    public let currency: String?

    public init(
        productId: String,
        status: SubscriptionStatus,
        store: Store,
        purchaseDate: Date? = nil,
        expiresDate: Date? = nil,
        willRenew: Bool = false,
        price: Decimal? = nil,
        currency: String? = nil
    ) {
        self.productId = productId
        self.status = status
        self.store = store
        self.purchaseDate = purchaseDate
        self.expiresDate = expiresDate
        self.willRenew = willRenew
        self.price = price
        self.currency = currency
    }
}

/// Subscription status
public enum SubscriptionStatus: String, Codable, Sendable {
    case active = "active"
    case cancelled = "cancelled"
    case expired = "expired"
    case billingRetry = "billing_retry"
    case gracePeriod = "grace_period"
    case paused = "paused"
    case pending = "pending"

    /// Whether this status grants access
    public var grantsAccess: Bool {
        switch self {
        case .active, .gracePeriod:
            return true
        case .cancelled, .expired, .billingRetry, .paused, .pending:
            return false
        }
    }
}
