import Foundation
import StoreKit

/// One-time "Premium" lifetime purchase handler using StoreKit 2.
/// Persists entitlement to UserDefaults so the check is synchronous on launch.
@MainActor
@Observable
final class PremiumManager {
    // TODO: Create this product ID in App Store Connect as a Non-Consumable IAP.
    static let productID = "com.logncomplexity.chessight.premium_lifetime"

    private let entitlementKey = "premium.lifetime.entitled"

    var isPremium: Bool = false
    var product: Product?
    var isPurchasing = false
    var purchaseError: String?

    private var transactionListener: Task<Void, Never>?

    init() {
        isPremium = UserDefaults.standard.bool(forKey: entitlementKey)
        transactionListener = listenForTransactions()
    }

    func start() async {
        await loadProduct()
        await refreshEntitlement()
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
        } catch {
            purchaseError = "Failed to load product: \(error.localizedDescription)"
        }
    }

    /// Returns true if purchase completed and entitlement granted.
    @discardableResult
    func purchase() async -> Bool {
        guard let product else {
            await loadProduct()
            guard product != nil else {
                purchaseError = "Product not available"
                return false
            }
            return await purchase()
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let tx = try checkVerified(verification)
                await grantEntitlement()
                await tx.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            return false
        }
    }

    /// Re-check all current entitlements. Used by Restore Purchases and on launch.
    func refreshEntitlement() async {
        var entitled = false
        for await verification in Transaction.currentEntitlements {
            if case .verified(let tx) = verification,
               tx.productID == Self.productID,
               tx.revocationDate == nil {
                entitled = true
            }
        }
        if entitled && !isPremium {
            await grantEntitlement()
        } else if !entitled && isPremium {
            // Revoked (e.g., refund) — honor it.
            isPremium = false
            UserDefaults.standard.set(false, forKey: entitlementKey)
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlement()
    }

    // MARK: - Private

    private func grantEntitlement() async {
        isPremium = true
        UserDefaults.standard.set(true, forKey: entitlementKey)
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await verification in Transaction.updates {
                guard let self else { return }
                if case .verified(let tx) = verification,
                   tx.productID == Self.productID {
                    if tx.revocationDate == nil {
                        await self.grantEntitlement()
                    } else {
                        await MainActor.run {
                            self.isPremium = false
                            UserDefaults.standard.set(false, forKey: self.entitlementKey)
                        }
                    }
                    await tx.finish()
                }
            }
        }
    }

    // MARK: - Display helpers

    /// Empty until StoreKit loads the product. Views should hide the price chip
    /// when empty rather than rendering a dash or placeholder.
    var displayPrice: String {
        product?.displayPrice ?? ""
    }

}
