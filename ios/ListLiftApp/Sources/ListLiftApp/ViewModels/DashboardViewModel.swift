import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var account: Account?
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let dataStore: DataStore

    init(environment: AppEnvironment) {
        self.dataStore = environment.dataStore
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        items = await dataStore.getItems().sorted(by: { $0.updatedAt > $1.updatedAt })
        account = await dataStore.getAccount()
    }
}
