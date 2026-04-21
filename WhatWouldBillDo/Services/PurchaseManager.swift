import Foundation
import StoreKit
import Observation

@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    let productIDs: [String] = [
        "com.whatwouldbilldo.app.weekly",
        "com.whatwouldbilldo.app.monthly",
        "com.whatwouldbilldo.app.yearly"
    ]

    var products: [Product] = []
    var isSubscribed: Bool = false
    var activeProductID: String? = nil
    var isLoadingProducts: Bool = false
    var lastError: String? = nil

    private var updatesTask: Task<Void, Never>? = nil

    private init() {
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(verificationResult: result)
            }
        }
    }


    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: productIDs)
            self.products = loaded.sorted { lhs, rhs in
                productIDs.firstIndex(of: lhs.id) ?? 0 < productIDs.firstIndex(of: rhs.id) ?? 0
            }
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    @discardableResult
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                self.isSubscribed = true
                self.activeProductID = transaction.productID
                syncAppState()
                return true
            case .unverified:
                return false
            }
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }

    func updateSubscriptionStatus() async {
        var subscribed = false
        var activeID: String? = nil
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if !transaction.isExpired && transaction.revocationDate == nil {
                    subscribed = true
                    activeID = transaction.productID
                }
            }
        }
        self.isSubscribed = subscribed
        self.activeProductID = activeID
        syncAppState()
    }

    private func handle(verificationResult result: VerificationResult<Transaction>) async {
        if case .verified(let transaction) = result {
            await transaction.finish()
            await updateSubscriptionStatus()
        }
    }

    private func syncAppState() {
        UserDefaults.standard.set(isSubscribed, forKey: "isSubscribed")
    }
}

private extension Transaction {
    var isExpired: Bool {
        if let exp = expirationDate { return exp < Date() }
        return false
    }
}
