import Foundation

@MainActor
final class TitleGenerationViewModel: ObservableObject {
    @Published var options: [ListingText] = []
    @Published var selectedTone: TitleTone = .seo
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var titleService: TitleGenerationService?
    private var dataStore: DataStore?
    private var analytics: AnalyticsService?
    private var item: Item

    init(item: Item) {
        self.item = item
    }

    func configure(with environment: AppEnvironment) {
        self.titleService = environment.titleService
        self.dataStore = environment.dataStore
        self.analytics = environment.analyticsService
    }

    func generate() async {
        guard let titleService, let dataStore else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            options = try await titleService.generateTitles(for: item, tone: selectedTone)
            item.titleOptions = options
            item.selectedTitleId = options.first?.id
            item.description = options.first?.description ?? item.description
            await dataStore.upsert(item)
        } catch {
            errorMessage = "Unable to generate titles right now."
        }
    }

    func choose(option: ListingText) async {
        guard let dataStore else { return }
        item.selectedTitleId = option.id
        item.description = option.description
        await dataStore.upsert(item)
    }
}
