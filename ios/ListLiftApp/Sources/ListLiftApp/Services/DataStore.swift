import Foundation

actor DataStore {
    private let itemsKey = "listlift.items"
    private let accountKey = "listlift.account"
    private var itemsCache: [Item] = []
    private var account: Account = Account(
        userId: UUID(),
        plan: .free,
        quotas: .init(processedListings: 0, processedListingsLimit: SubscriptionPlan.free.listingLimit),
        ebayAuth: nil,
        templates: [],
        policiesCache: .init(shippingPolicies: [], paymentPolicies: [], returnPolicies: [])
    )

    init() {
        Task { await load() }
    }

    func load() async {
        itemsCache = await read([Item].self, key: itemsKey) ?? []
        if let storedAccount = await read(Account.self, key: accountKey) {
            account = storedAccount
        }
    }

    func saveItems(_ items: [Item]) async {
        itemsCache = items
        await write(items, key: itemsKey)
    }

    func getItems() async -> [Item] {
        itemsCache
    }

    func upsert(_ item: Item) async {
        if let index = itemsCache.firstIndex(where: { $0.id == item.id }) {
            itemsCache[index] = item
        } else {
            itemsCache.append(item)
        }
        await write(itemsCache, key: itemsKey)
    }

    func delete(_ item: Item) async {
        itemsCache.removeAll { $0.id == item.id }
        await write(itemsCache, key: itemsKey)
    }

    func getAccount() async -> Account { account }

    func saveAccount(_ account: Account) async {
        self.account = account
        await write(account, key: accountKey)
    }

    private func read<T: Decodable>(_ type: T.Type, key: String) async -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder.apiDecoder.decode(T.self, from: data)
    }

    private func write<T: Encodable>(_ value: T, key: String) async {
        let data = try? JSONEncoder.apiEncoder.encode(value)
        UserDefaults.standard.set(data, forKey: key)
    }
}
