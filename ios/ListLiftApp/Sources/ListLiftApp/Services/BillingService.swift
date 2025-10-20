import Foundation
import StoreKit

actor BillingService: NSObject, ObservableObject {
    @Published private(set) var products: [Product] = []
    private let dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore
        super.init()
        Task { await loadProducts() }
    }

    private func loadProducts() async {
        do {
            products = try await Product.products(for: ["listlift.pro", "listlift.power"])
        } catch {
            print("Failed to load IAP products: \(error)")
        }
    }

    func purchase(plan: SubscriptionPlan) async throws {
        guard let product = products.first(where: { $0.id.contains(plan.rawValue) }) else { return }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified:
                var account = await dataStore.getAccount()
                account.plan = plan
                account.quotas = .init(processedListings: account.quotas.processedListings, processedListingsLimit: plan.listingLimit)
                await dataStore.saveAccount(account)
            case .unverified:
                throw BillingError.unverifiedTransaction
            }
        case .userCancelled:
            throw BillingError.userCancelled
        default:
            break
        }
    }

    func trackProcessedListing() async throws {
        var account = await dataStore.getAccount()
        account.quotas.processedListings += 1
        if account.quotas.processedListings >= account.quotas.processedListingsLimit {
            throw BillingError.quotaExceeded
        }
        await dataStore.saveAccount(account)
    }

    enum BillingError: Error {
        case userCancelled
        case unverifiedTransaction
        case quotaExceeded
    }
}
