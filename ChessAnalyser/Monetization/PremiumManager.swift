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
        CrashLogger.logMonetization("PremiumManager.start — productID=\(Self.productID), isPremium=\(isPremium)")
        await loadProduct()
        await refreshEntitlement()
    }

    func loadProduct() async {
        CrashLogger.logMonetization("Loading product \(Self.productID)")
        do {
            let products = try await Product.products(for: [Self.productID])
            if let p = products.first {
                product = p
                CrashLogger.logMonetization("Product loaded: id=\(p.id) displayPrice=\(p.displayPrice)")
            } else {
                product = nil
                CrashLogger.logMonetization("Product load returned empty — check App Store Connect IAP exists, product ID matches, and Paid Apps Agreement is signed")
            }
        } catch {
            purchaseError = "Failed to load product: \(error.localizedDescription)"
            CrashLogger.logMonetizationError(error, context: "Product.products(for:)")
        }
    }

    /// Returns true if purchase completed and entitlement granted.
    @discardableResult
    func purchase() async -> Bool {
        guard let product else {
            CrashLogger.logMonetization("Purchase requested but product is nil — reloading")
            await loadProduct()
            guard product != nil else {
                purchaseError = "Product not available"
                CrashLogger.logMonetization("Purchase aborted: product still nil after reload")
                return false
            }
            return await purchase()
        }

        CrashLogger.logMonetization("Purchase starting for \(product.id)")
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let tx = try checkVerified(verification)
                CrashLogger.logMonetization("Purchase succeeded: originalID=\(tx.originalID)")
                await grantEntitlement()
                await tx.finish()
                return true
            case .userCancelled:
                CrashLogger.logMonetization("Purchase cancelled by user")
                return false
            case .pending:
                CrashLogger.logMonetization("Purchase pending (e.g. Ask to Buy / SCA)")
                return false
            @unknown default:
                CrashLogger.logMonetization("Purchase returned unknown result")
                return false
            }
        } catch {
            purchaseError = error.localizedDescription
            CrashLogger.logMonetizationError(error, context: "product.purchase()")
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
        CrashLogger.logMonetization("Restore requested")
        try? await AppStore.sync()
        await refreshEntitlement()
        CrashLogger.logMonetization("Restore finished — isPremium=\(isPremium)")
    }

    // MARK: - Private

    private func grantEntitlement() async {
        isPremium = true
        UserDefaults.standard.set(true, forKey: entitlementKey)
        CrashLogger.logMonetization("Entitlement granted — isPremium=true")
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
