import Foundation

/// Errors that can occur in SubscriptionKit
public enum SubscriptionKitError: LocalizedError, Sendable {

    /// SDK has not been configured yet
    case notConfigured

    /// User cancelled the purchase
    case purchaseCancelled

    /// Purchase is pending external action (e.g., parental approval)
    case purchasePending

    /// Transaction verification failed
    case verificationFailed

    /// Network request failed
    case networkError

    /// Server returned an error
    case serverError(statusCode: Int)

    /// Product not found
    case productNotFound(productId: String)

    /// No active subscription found
    case noActiveSubscription

    /// Unknown error occurred
    case unknownError

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "SubscriptionKit has not been configured. Call configure(apiKey:) first."
        case .purchaseCancelled:
            return "Purchase was cancelled."
        case .purchasePending:
            return "Purchase is pending approval."
        case .verificationFailed:
            return "Transaction verification failed."
        case .networkError:
            return "Network request failed. Please check your connection."
        case .serverError(let statusCode):
            return "Server error occurred (status: \(statusCode))."
        case .productNotFound(let productId):
            return "Product not found: \(productId)"
        case .noActiveSubscription:
            return "No active subscription found."
        case .unknownError:
            return "An unknown error occurred."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notConfigured:
            return "Call SubscriptionKit.shared.configure(apiKey:) in your app's initialization."
        case .purchaseCancelled:
            return nil
        case .purchasePending:
            return "The purchase requires approval. Please try again later."
        case .verificationFailed:
            return "Please try the purchase again or contact support."
        case .networkError:
            return "Check your internet connection and try again."
        case .serverError:
            return "Please try again later."
        case .productNotFound:
            return "Ensure the product is configured in App Store Connect."
        case .noActiveSubscription:
            return "Subscribe to access this feature."
        case .unknownError:
            return "Please try again or contact support."
        }
    }
}
