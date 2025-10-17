import Foundation

@MainActor
final class PublishViewModel: ObservableObject {
    @Published var publishResult: PublishResult?
    @Published var errorMessage: String?
    @Published var isPublishing = false

    private var publishService: EbayPublishingService?
    private var dataStore: DataStore?
    private var analytics: AnalyticsService?
    private var item: Item

    init(item: Item) {
        self.item = item
    }

    func configure(with environment: AppEnvironment) {
        self.publishService = environment.publishService
        self.dataStore = environment.dataStore
        self.analytics = environment.analyticsService
    }

    func configureIfNeeded(environment: AppEnvironment) {
        if publishService == nil {
            configure(with: environment)
        }
    }

    func publish(offer: PublishOffer) async {
        guard let publishService, let dataStore else { return }
        isPublishing = true
        defer { isPublishing = false }
        do {
            let result = try await publishService.publish(item: item, offer: offer)
            publishResult = result
            analytics?.track(.publishedSuccess, properties: ["listingId": result.listingId])
            var stored = item
            stored.marketplaceStatus.ebay = .published
            await dataStore.upsert(stored)
        } catch {
            errorMessage = "Publish failed. Check specifics and policies."
        }
    }
}
