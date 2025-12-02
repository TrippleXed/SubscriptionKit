import Foundation
import StoreKit

/// A collection of offerings available to the user
public struct Offerings: Sendable {

    /// All offerings keyed by identifier
    public let all: [String: Offering]

    /// The default offering (first one, or "default" if exists)
    public var current: Offering? {
        return all["default"] ?? all.values.first
    }

    public init(all: [String: Offering]) {
        self.all = all
    }

    /// Get a specific offering by identifier
    public subscript(identifier: String) -> Offering? {
        return all[identifier]
    }
}

/// A group of packages (products) presented together
public struct Offering: Sendable {

    /// Unique identifier for this offering
    public let identifier: String

    /// Packages available in this offering
    public let packages: [Package]

    /// The "main" package - typically monthly or the most popular
    public var mainPackage: Package? {
        return packages.first { $0.packageType == .monthly } ?? packages.first
    }

    /// Get package by type
    public func package(for type: PackageType) -> Package? {
        return packages.first { $0.packageType == type }
    }

    public init(identifier: String, packages: [Package]) {
        self.identifier = identifier
        self.packages = packages
    }
}

/// A purchasable package wrapping a StoreKit Product
public struct Package: Sendable {

    /// The underlying StoreKit product
    public let product: Product

    /// Inferred package type based on subscription period
    public var packageType: PackageType {
        guard let subscription = product.subscription else {
            return .lifetime
        }

        switch subscription.subscriptionPeriod.unit {
        case .day:
            return subscription.subscriptionPeriod.value == 7 ? .weekly : .custom
        case .week:
            return .weekly
        case .month:
            switch subscription.subscriptionPeriod.value {
            case 1: return .monthly
            case 3: return .threeMonth
            case 6: return .sixMonth
            default: return .custom
            }
        case .year:
            return .annual
        @unknown default:
            return .custom
        }
    }

    /// Localized price string
    public var localizedPriceString: String {
        return product.displayPrice
    }

    /// Price per month for comparison
    public var pricePerMonth: Decimal? {
        guard let subscription = product.subscription else { return nil }

        let months: Decimal
        switch subscription.subscriptionPeriod.unit {
        case .day:
            months = Decimal(subscription.subscriptionPeriod.value) / 30
        case .week:
            months = Decimal(subscription.subscriptionPeriod.value) / 4
        case .month:
            months = Decimal(subscription.subscriptionPeriod.value)
        case .year:
            months = Decimal(subscription.subscriptionPeriod.value) * 12
        @unknown default:
            return nil
        }

        guard months > 0 else { return nil }
        return product.price / months
    }

    public init(product: Product) {
        self.product = product
    }
}

/// Package duration types
public enum PackageType: String, Sendable {
    case weekly
    case monthly
    case threeMonth
    case sixMonth
    case annual
    case lifetime
    case custom
}
