# SubscriptionKit

A lightweight iOS SDK for managing in-app subscriptions with your own backend. Drop-in replacement for RevenueCat.

## Installation

### Swift Package Manager

Add SubscriptionKit to your project via Xcode:

1. Go to **File → Add Package Dependencies**
2. Enter: `https://github.com/jasoncameron/SubscriptionKit`
3. Select your target and click **Add Package**

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/jasoncameron/SubscriptionKit", from: "1.0.0")
]
```

## Quick Start

### 1. Configure on App Launch

```swift
import SubscriptionKit

@main
struct MyApp: App {
    init() {
        SubscriptionKit.shared.configure(apiKey: "sk_your_api_key_here")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Check Subscription Status

```swift
// Get current customer info
let customerInfo = try await SubscriptionKit.shared.getCustomerInfo()

// Check if user has active subscription
if customerInfo.hasActiveSubscription {
    // Unlock premium features
}

// Check specific entitlement
if customerInfo.isEntitled(to: "premium") {
    // User has premium access
}
```

### 3. Make a Purchase

```swift
// Fetch products from App Store
let products = try await SubscriptionKit.shared.getProducts([
    "com.yourapp.monthly",
    "com.yourapp.yearly"
])

// Purchase a product
let customerInfo = try await SubscriptionKit.shared.purchase(products.first!)
```

### 4. Restore Purchases

```swift
let customerInfo = try await SubscriptionKit.shared.restorePurchases()
```

## SwiftUI Integration

### Using the Built-in PaywallView

```swift
import SubscriptionKit
import SwiftUI

struct ContentView: View {
    @State private var showPaywall = false
    @State private var products: [Product] = []

    var body: some View {
        VStack {
            Button("Subscribe") {
                showPaywall = true
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                products: products,
                title: "Unlock Premium",
                subtitle: "Get access to all features",
                features: [
                    "Unlimited exports",
                    "Cloud sync",
                    "Priority support"
                ],
                onPurchaseComplete: { customerInfo in
                    print("Purchased! Active: \(customerInfo.activeSubscriptions)")
                }
            )
        }
        .task {
            products = try? await SubscriptionKit.shared.getProducts([
                "com.yourapp.monthly",
                "com.yourapp.yearly"
            ]) ?? []
        }
    }
}
```

### Observing Customer Info Changes

```swift
struct ContentView: View {
    @ObservedObject var subscriptionKit = SubscriptionKit.shared

    var body: some View {
        VStack {
            if subscriptionKit.customerInfo?.hasActiveSubscription == true {
                Text("Premium User")
            } else {
                Text("Free User")
            }
        }
    }
}
```

## User Authentication

### Anonymous Users (Default)

By default, SubscriptionKit creates an anonymous user ID. This is stored locally and persists across app launches.

### Identified Users

If your app has user accounts, pass the user ID during configuration or login:

```swift
// On app launch with known user
SubscriptionKit.shared.configure(
    apiKey: "sk_your_api_key",
    appUserId: user.id
)

// Or login after configuration
let customerInfo = try await SubscriptionKit.shared.logIn(appUserId: user.id)

// Logout (switches to anonymous)
let customerInfo = try await SubscriptionKit.shared.logOut()
```

## Error Handling

```swift
do {
    let customerInfo = try await SubscriptionKit.shared.purchase(product)
} catch SubscriptionKitError.purchaseCancelled {
    // User cancelled, do nothing
} catch SubscriptionKitError.purchasePending {
    // Purchase pending parental approval
    showAlert("Purchase requires approval")
} catch SubscriptionKitError.networkError {
    // Network issue
    showAlert("Please check your connection")
} catch {
    // Other error
    showAlert(error.localizedDescription)
}
```

## Configuration Options

```swift
SubscriptionKit.shared.configure(
    apiKey: "sk_your_api_key",
    appUserId: "optional_user_id",           // nil for anonymous
    baseURL: URL(string: "https://...")      // nil for default
)

// Set log level (default: .info)
Logger.logLevel = .debug  // .debug, .info, .warning, .error, .none
```

## Requirements

- iOS 15.0+
- macOS 12.0+
- watchOS 8.0+
- tvOS 15.0+
- Xcode 15.0+
- Swift 5.9+

## License

MIT License - see LICENSE file for details.
