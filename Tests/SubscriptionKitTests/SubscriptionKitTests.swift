import XCTest
@testable import SubscriptionKit

final class SubscriptionKitTests: XCTestCase {

    func testCustomerInfoEntitlementCheck() {
        let customerInfo = CustomerInfo(
            userId: "test_user",
            entitlements: [
                "premium": Entitlement(isActive: true, productId: "com.app.premium"),
                "pro": Entitlement(isActive: false, productId: "com.app.pro")
            ],
            activeSubscriptions: ["com.app.premium"],
            allPurchasedProductIds: ["com.app.premium", "com.app.pro"]
        )

        XCTAssertTrue(customerInfo.isEntitled(to: "premium"))
        XCTAssertFalse(customerInfo.isEntitled(to: "pro"))
        XCTAssertFalse(customerInfo.isEntitled(to: "nonexistent"))
        XCTAssertTrue(customerInfo.hasActiveSubscription)
        XCTAssertTrue(customerInfo.hasAnyEntitlement)
    }

    func testCustomerInfoNoSubscriptions() {
        let customerInfo = CustomerInfo(
            userId: "test_user",
            entitlements: [:],
            activeSubscriptions: [],
            allPurchasedProductIds: []
        )

        XCTAssertFalse(customerInfo.hasActiveSubscription)
        XCTAssertFalse(customerInfo.hasAnyEntitlement)
    }

    func testEntitlementExpiringSoon() {
        let threeDaysFromNow = Date().addingTimeInterval(3 * 24 * 60 * 60)
        let entitlement = Entitlement(
            isActive: true,
            productId: "com.app.premium",
            expiresDate: threeDaysFromNow,
            willRenew: false
        )

        XCTAssertTrue(entitlement.isExpiringSoon)
    }

    func testEntitlementNotExpiringSoon() {
        let thirtyDaysFromNow = Date().addingTimeInterval(30 * 24 * 60 * 60)
        let entitlement = Entitlement(
            isActive: true,
            productId: "com.app.premium",
            expiresDate: thirtyDaysFromNow,
            willRenew: true
        )

        XCTAssertFalse(entitlement.isExpiringSoon)
    }

    func testSubscriptionStatusGrantsAccess() {
        XCTAssertTrue(SubscriptionStatus.active.grantsAccess)
        XCTAssertTrue(SubscriptionStatus.gracePeriod.grantsAccess)
        XCTAssertFalse(SubscriptionStatus.expired.grantsAccess)
        XCTAssertFalse(SubscriptionStatus.cancelled.grantsAccess)
        XCTAssertFalse(SubscriptionStatus.billingRetry.grantsAccess)
    }
}
