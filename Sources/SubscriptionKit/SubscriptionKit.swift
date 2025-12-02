import Foundation
import StoreKit

/// SubscriptionKit - A lightweight subscription management SDK
/// Replacement for RevenueCat with your own backend
@MainActor
public final class SubscriptionKit: ObservableObject {

    // MARK: - Singleton

    /// Shared instance of SubscriptionKit
    public static let shared = SubscriptionKit()

    // MARK: - Published Properties

    /// Current customer info with entitlements
    @Published public private(set) var customerInfo: CustomerInfo?

    /// Whether the SDK is currently loading data
    @Published public private(set) var isLoading = false

    /// Current offerings available for purchase
    @Published public private(set) var offerings: Offerings?

    // MARK: - Private Properties

    private var apiKey: String?
    private var appUserId: String?
    private var baseURL: URL?
    private var isConfigured = false

    private let cache = CustomerInfoCache()
    private var transactionListener: Task<Void, Never>?

    // MARK: - Initialization

    private init() {}

    // MARK: - Configuration

    /// Configure SubscriptionKit with your API key
    /// - Parameters:
    ///   - apiKey: Your SubscriptionKit API key (starts with sk_)
    ///   - appUserId: Optional user identifier. If nil, uses anonymous ID
    ///   - baseURL: Optional custom backend URL (defaults to production)
    public func configure(
        apiKey: String,
        appUserId: String? = nil,
        baseURL: URL? = nil
    ) {
        guard !isConfigured else {
            Logger.warning("SubscriptionKit is already configured")
            return
        }

        self.apiKey = apiKey
        self.appUserId = appUserId ?? getOrCreateAnonymousId()
        self.baseURL = baseURL ?? URL(string: "https://aircrew24-admin.vercel.app")!
        self.isConfigured = true

        Logger.info("SubscriptionKit configured for user: \(self.appUserId ?? "unknown")")

        // Start listening for transactions
        startTransactionListener()

        // Load cached customer info
        if let cached = cache.load() {
            self.customerInfo = cached
        }

        // Fetch fresh customer info in background
        Task {
            try? await refreshCustomerInfo()
        }
    }

    /// Update the current user ID (e.g., after login)
    /// - Parameter appUserId: The new user identifier
    public func logIn(appUserId: String) async throws -> CustomerInfo {
        guard isConfigured else {
            throw SubscriptionKitError.notConfigured
        }

        self.appUserId = appUserId
        cache.clear()

        return try await refreshCustomerInfo()
    }

    /// Log out the current user and switch to anonymous ID
    public func logOut() async throws -> CustomerInfo {
        guard isConfigured else {
            throw SubscriptionKitError.notConfigured
        }

        self.appUserId = createAnonymousId()
        cache.clear()

        return try await refreshCustomerInfo()
    }

    // MARK: - Purchases

    /// Purchase a product
    /// - Parameter product: The StoreKit Product to purchase
    /// - Returns: Updated CustomerInfo after purchase
    @discardableResult
    public func purchase(_ product: Product) async throws -> CustomerInfo {
        guard isConfigured else {
            throw SubscriptionKitError.notConfigured
        }

        isLoading = true
        defer { isLoading = false }

        Logger.info("Starting purchase for product: \(product.id)")

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerification(verification)

            // Verify with backend
            let customerInfo = try await verifyTransaction(transaction)

            // Finish the transaction
            await transaction.finish()

            Logger.info("Purchase successful for product: \(product.id)")
            return customerInfo

        case .userCancelled:
            Logger.info("Purchase cancelled by user")
            throw SubscriptionKitError.purchaseCancelled

        case .pending:
            Logger.info("Purchase pending approval")
            throw SubscriptionKitError.purchasePending

        @unknown default:
            throw SubscriptionKitError.unknownError
        }
    }

    /// Restore previous purchases
    /// - Returns: Updated CustomerInfo after restore
    @discardableResult
    public func restorePurchases() async throws -> CustomerInfo {
        guard isConfigured else {
            throw SubscriptionKitError.notConfigured
        }

        isLoading = true
        defer { isLoading = false }

        Logger.info("Restoring purchases...")

        // Sync with App Store
        try await AppStore.sync()

        // Verify all current entitlements
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                _ = try? await verifyTransaction(transaction)
            }
        }

        // Refresh customer info
        let customerInfo = try await refreshCustomerInfo()

        Logger.info("Restore complete")
        return customerInfo
    }

    // MARK: - Customer Info

    /// Refresh customer info from the server
    /// - Returns: Updated CustomerInfo
    @discardableResult
    public func refreshCustomerInfo() async throws -> CustomerInfo {
        guard isConfigured, let apiKey = apiKey, let baseURL = baseURL, let userId = appUserId else {
            throw SubscriptionKitError.notConfigured
        }

        let url = baseURL.appendingPathComponent("/api/v1/customers/\(userId)")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SubscriptionKitError.networkError
        }

        if httpResponse.statusCode == 404 {
            // User doesn't exist yet - return empty customer info
            let emptyInfo = CustomerInfo(
                userId: userId,
                entitlements: [:],
                activeSubscriptions: [],
                allPurchasedProductIds: []
            )
            self.customerInfo = emptyInfo
            return emptyInfo
        }

        guard httpResponse.statusCode == 200 else {
            Logger.error("Failed to fetch customer info: \(httpResponse.statusCode)")
            throw SubscriptionKitError.serverError(statusCode: httpResponse.statusCode)
        }

        let customerResponse = try JSONDecoder().decode(CustomerInfoResponse.self, from: data)
        let customerInfo = customerResponse.customerInfo

        self.customerInfo = customerInfo
        cache.save(customerInfo)

        return customerInfo
    }

    /// Get the current customer info (from cache if available)
    public func getCustomerInfo() async throws -> CustomerInfo {
        if let cached = customerInfo {
            // Return cached but refresh in background
            Task {
                try? await refreshCustomerInfo()
            }
            return cached
        }

        return try await refreshCustomerInfo()
    }

    // MARK: - Products & Offerings

    /// Fetch available products from App Store
    /// - Parameter productIds: Array of product identifiers to fetch
    /// - Returns: Array of StoreKit Products
    public func getProducts(_ productIds: [String]) async throws -> [Product] {
        return try await Product.products(for: Set(productIds))
    }

    /// Load offerings (products grouped by identifier)
    /// - Parameter productIds: Dictionary mapping offering ID to product IDs
    public func loadOfferings(_ productIds: [String: [String]]) async throws -> Offerings {
        var offeringsDict: [String: Offering] = [:]

        for (offeringId, ids) in productIds {
            let products = try await getProducts(ids)
            let packages = products.map { Package(product: $0) }
            offeringsDict[offeringId] = Offering(identifier: offeringId, packages: packages)
        }

        let offerings = Offerings(all: offeringsDict)
        self.offerings = offerings
        return offerings
    }

    // MARK: - Private Methods

    private func verifyTransaction(_ transaction: Transaction) async throws -> CustomerInfo {
        guard let apiKey = apiKey, let baseURL = baseURL else {
            throw SubscriptionKitError.notConfigured
        }

        let url = baseURL.appendingPathComponent("/api/v1/receipts/verify")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "transactionId": String(transaction.id),
            "appUserId": appUserId ?? ""
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SubscriptionKitError.verificationFailed
        }

        let verifyResponse = try JSONDecoder().decode(VerifyReceiptResponse.self, from: data)
        let customerInfo = verifyResponse.customerInfo

        self.customerInfo = customerInfo
        cache.save(customerInfo)

        return customerInfo
    }

    private func checkVerification<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            Logger.error("Transaction verification failed: \(error)")
            throw SubscriptionKitError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    private func startTransactionListener() {
        transactionListener = Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerification(result)
                    _ = try await verifyTransaction(transaction)
                    await transaction.finish()
                    Logger.info("Processed transaction update: \(transaction.id)")
                } catch {
                    Logger.error("Failed to process transaction update: \(error)")
                }
            }
        }
    }

    private func getOrCreateAnonymousId() -> String {
        let key = "com.subscriptionkit.anonymousId"
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let newId = createAnonymousId()
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }

    private func createAnonymousId() -> String {
        return "$anonymous_\(UUID().uuidString.lowercased())"
    }
}
