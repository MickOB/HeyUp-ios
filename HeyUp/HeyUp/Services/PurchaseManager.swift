import Foundation
import Combine
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let monthlyID = "fit.heyup.pro.monthly"
    static let annualID = "fit.heyup.pro.annual"
    static let lifetimeID = "fit.heyup.pro.lifetime"

    private static let productIDs: Set<String> = [monthlyID, annualID, lifetimeID]

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = true
    @Published private(set) var isPurchasing = false
    @Published var purchaseError: String?

    private var transactionUpdates: Task<Void, Never>?

    init() {
        transactionUpdates = observeTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
            isLoading = false
        }
    }

    deinit {
        transactionUpdates?.cancel()
    }

    var hasProAccess: Bool {
        !purchasedProductIDs.isDisjoint(with: Self.productIDs)
    }

    var monthlyProduct: Product? { product(withID: Self.monthlyID) }
    var annualProduct: Product? { product(withID: Self.annualID) }
    var lifetimeProduct: Product? { product(withID: Self.lifetimeID) }

    func loadProducts() async {
        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { productOrder($0.id) < productOrder($1.id) }
            purchaseError = nil
        } catch {
            purchaseError = "Purchases are temporarily unavailable. Please try again."
        }
    }

    func purchase(_ product: Product) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                await transaction.finish()
                await refreshEntitlements()
                purchaseError = nil
                return true
            case .pending:
                purchaseError = "Your purchase is waiting for approval."
            case .userCancelled:
                purchaseError = nil
            @unknown default:
                purchaseError = "The purchase could not be completed."
            }
        } catch {
            purchaseError = "The purchase could not be completed. Please try again."
        }
        return false
    }

    func restorePurchases() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            purchaseError = hasProAccess ? nil : "No previous HeyUp purchase was found."
        } catch {
            purchaseError = "Purchases could not be restored. Please try again."
        }
    }

    func refreshEntitlements() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result),
                  transaction.revocationDate == nil else { continue }
            active.insert(transaction.productID)
        }
        purchasedProductIDs = active
    }

    private func product(withID id: String) -> Product? {
        products.first { $0.id == id }
    }

    private func productOrder(_ id: String) -> Int {
        switch id {
        case Self.annualID: return 0
        case Self.monthlyID: return 1
        default: return 2
        }
    }

    private func observeTransactions() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self,
                      let transaction = try? self.verified(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified: throw PurchaseError.failedVerification
        }
    }
}

private enum PurchaseError: Error {
    case failedVerification
}
