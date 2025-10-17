import Foundation

@MainActor
final class CompsViewModel: ObservableObject {
    @Published var pricingSummary: PricingSummary?
    @Published var filters = PricingFilters()
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var pricingService: PricingService?
    private var analytics: AnalyticsService?
    private var itemProvider: () -> Item

    init(itemProvider: @escaping () -> Item) {
        self.itemProvider = itemProvider
    }

    func configure(with environment: AppEnvironment) {
        self.pricingService = environment.pricingService
        self.analytics = environment.analyticsService
    }

    func fetch() async {
        guard let pricingService else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let summary = try await pricingService.fetchComps(for: itemProvider(), filters: filters)
            pricingSummary = summary
            analytics?.track(.compsViewed, properties: ["count": summary.items.count])
        } catch {
            errorMessage = "Unable to load comparables."
        }
    }

    func apply(filters: PricingFilters) async {
        self.filters = filters
        await fetch()
    }
}
