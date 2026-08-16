import StoreKit
import Foundation

@MainActor
class StoreKitService: ObservableObject {
    static let shared = StoreKitService()

    // Product IDs — configure these in App Store Connect
    static let monthlyId = "com.brewscan.pro.monthly"
    static let yearlyId  = "com.brewscan.pro.yearly"

    @Published var products: [Product] = []
    @Published var isSubscribed: Bool = false
    @Published var isPurchasing: Bool = false
    @Published var purchaseError: String?

    private var updateListenerTask: Task<Void, Error>?

    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: [Self.monthlyId, Self.yearlyId])
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            print("[StoreKit] Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updateSubscriptionStatus()
                    return true
                case .unverified:
                    purchaseError = "Purchase could not be verified."
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                purchaseError = "Purchase is pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Subscription Status

    func updateSubscriptionStatus() async {
        var hasActive = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                let isBrewScanSubscription = [
                    Self.monthlyId,
                    Self.yearlyId
                ].contains(transaction.productID)
                let isNotRevoked = transaction.revocationDate == nil
                let isNotExpired = transaction.expirationDate.map { $0 > Date() } ?? true

                if isBrewScanSubscription && isNotRevoked && isNotExpired {
                    hasActive = true
                }
            }
        }
        isSubscribed = hasActive
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self?.updateSubscriptionStatus()
                }
            }
        }
    }

    // MARK: - Convenience

    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyId } }
    var yearlyProduct:  Product? { products.first { $0.id == Self.yearlyId  } }

    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }
}
