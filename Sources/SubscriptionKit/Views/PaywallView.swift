#if os(iOS)
import SwiftUI
import StoreKit

/// A customizable paywall view for presenting subscription options
@available(iOS 16.0, *)
public struct PaywallView: View {

    @ObservedObject private var subscriptionKit = SubscriptionKit.shared

    @Environment(\.dismiss) private var dismiss

    /// Products to display
    let products: [Product]

    /// Optional title override
    let title: String

    /// Optional subtitle override
    let subtitle: String

    /// Features to highlight
    let features: [String]

    /// Called when purchase completes successfully
    let onPurchaseComplete: ((CustomerInfo) -> Void)?

    /// Called when user dismisses without purchasing
    let onDismiss: (() -> Void)?

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    public init(
        products: [Product],
        title: String = "Unlock Premium",
        subtitle: String = "Get access to all features",
        features: [String] = [],
        onPurchaseComplete: ((CustomerInfo) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.products = products
        self.title = title
        self.subtitle = subtitle
        self.features = features
        self.onPurchaseComplete = onPurchaseComplete
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Features
                    if !features.isEmpty {
                        featuresSection
                    }

                    // Products
                    productsSection

                    // Purchase Button
                    purchaseButton

                    // Restore
                    restoreButton

                    // Terms
                    termsSection
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onDismiss?()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title2)
                    }
                }
            }
            .alert("Error", isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .onAppear {
            // Select first product by default
            if selectedProduct == nil {
                selectedProduct = products.first
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(features, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)

                    Text(feature)
                        .font(.body)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var productsSection: some View {
        VStack(spacing: 12) {
            ForEach(products, id: \.id) { product in
                ProductCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id
                ) {
                    selectedProduct = product
                }
            }
        }
    }

    private var purchaseButton: some View {
        Button {
            Task {
                await purchase()
            }
        } label: {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Subscribe")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedProduct != nil ? Color.accentColor : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(selectedProduct == nil || isPurchasing)
    }

    private var restoreButton: some View {
        Button {
            Task {
                await restore()
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .disabled(isPurchasing)
    }

    private var termsSection: some View {
        VStack(spacing: 4) {
            Text("Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Terms of Service", destination: URL(string: "https://apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                Link("Privacy Policy", destination: URL(string: "https://apple.com/privacy/")!)
            }
            .font(.caption2)
        }
        .padding(.top)
    }

    // MARK: - Actions

    private func purchase() async {
        guard let product = selectedProduct else { return }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let customerInfo = try await SubscriptionKit.shared.purchase(product)
            onPurchaseComplete?(customerInfo)
            dismiss()
        } catch SubscriptionKitError.purchaseCancelled {
            // User cancelled, do nothing
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let customerInfo = try await SubscriptionKit.shared.restorePurchases()
            if customerInfo.hasActiveSubscription {
                onPurchaseComplete?(customerInfo)
                dismiss()
            } else {
                errorMessage = "No active subscriptions found to restore."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Product Card

@available(iOS 16.0, *)
private struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if let subscription = product.subscription {
                        Text(periodDescription(subscription.subscriptionPeriod))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    if let subscription = product.subscription {
                        Text(pricePerPeriod(subscription.subscriptionPeriod))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(uiColor: .secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func periodDescription(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day: return period.value == 7 ? "Weekly" : "\(period.value) days"
        case .week: return "Weekly"
        case .month:
            switch period.value {
            case 1: return "Monthly"
            case 3: return "Quarterly"
            case 6: return "6 Months"
            default: return "\(period.value) months"
            }
        case .year: return "Yearly"
        @unknown default: return ""
        }
    }

    private func pricePerPeriod(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day: return "per day"
        case .week: return "per week"
        case .month: return "per month"
        case .year: return "per year"
        @unknown default: return ""
        }
    }
}
#endif
