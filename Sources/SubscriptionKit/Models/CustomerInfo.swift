import Foundation

/// Information about a customer's purchases and entitlements
public struct CustomerInfo: Codable, Equatable, Sendable {

    /// The unique identifier for this customer
    public let userId: String

    /// The original app user ID (may differ after transfers)
    public let originalAppUserId: String?

    /// Dictionary of entitlements keyed by product ID
    public let entitlements: [String: Entitlement]

    /// Array of currently active subscription product IDs
    public let activeSubscriptions: [String]

    /// Array of all product IDs ever purchased
    public let allPurchasedProductIds: [String]

    /// The latest expiration date across all subscriptions
    public let latestExpirationDate: Date?

    /// URL to manage subscriptions
    public let managementURL: URL?

    /// First time this customer was seen
    public let firstSeen: Date?

    /// Last time this customer was seen
    public let lastSeen: Date?

    /// All subscription details
    public let subscriptions: [SubscriptionInfo]?

    public init(
        userId: String,
        originalAppUserId: String? = nil,
        entitlements: [String: Entitlement],
        activeSubscriptions: [String],
        allPurchasedProductIds: [String],
        latestExpirationDate: Date? = nil,
        managementURL: URL? = nil,
        firstSeen: Date? = nil,
        lastSeen: Date? = nil,
        subscriptions: [SubscriptionInfo]? = nil
    ) {
        self.userId = userId
        self.originalAppUserId = originalAppUserId
        self.entitlements = entitlements
        self.activeSubscriptions = activeSubscriptions
        self.allPurchasedProductIds = allPurchasedProductIds
        self.latestExpirationDate = latestExpirationDate
        self.managementURL = managementURL
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
        self.subscriptions = subscriptions
    }

    /// Check if user has active entitlement for a product
    public func isEntitled(to productId: String) -> Bool {
        return entitlements[productId]?.isActive == true
    }

    /// Check if user has any active subscription
    public var hasActiveSubscription: Bool {
        return !activeSubscriptions.isEmpty
    }

    /// Check if user has any active entitlement
    public var hasAnyEntitlement: Bool {
        return entitlements.values.contains { $0.isActive }
    }
}

/// Response wrapper for customer info API
struct CustomerInfoResponse: Codable {
    let customerInfo: CustomerInfo
}

/// Response wrapper for receipt verification API
struct VerifyReceiptResponse: Codable {
    let success: Bool
    let customerInfo: CustomerInfo
    let transaction: TransactionDetails?
}

/// Transaction details from verification
struct TransactionDetails: Codable {
    let transactionId: String
    let originalTransactionId: String
    let productId: String
    let purchaseDate: Date?
    let expiresDate: Date?
    let environment: String?
}
