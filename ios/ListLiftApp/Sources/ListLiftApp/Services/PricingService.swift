import Foundation

actor PricingService {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func fetchComps(for item: Item, filters: PricingFilters) async throws -> PricingSummary {
        let request = PricingRequest(
            itemId: item.id,
            categoryId: item.categoryId,
            condition: item.condition.rawValue,
            filters: filters
        )
        let data = try JSONEncoder.apiEncoder.encode(request)
        let endpoint = Endpoint(path: "/pricing/comps", method: "POST", body: data)
        return try await httpClient.request(endpoint, decodeTo: PricingSummary.self)
    }
}

struct PricingFilters: Codable {
    var condition: String?
    var size: String?
    var shipping: ShippingOption?
    var location: String?

    enum ShippingOption: String, Codable, CaseIterable {
        case free
        case paid
    }
}

private struct PricingRequest: Codable {
    var itemId: UUID
    var categoryId: String?
    var condition: String
    var filters: PricingFilters
}
