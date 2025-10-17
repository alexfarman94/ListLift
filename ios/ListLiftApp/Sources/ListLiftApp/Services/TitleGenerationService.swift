import Foundation

actor TitleGenerationService {
    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func generateTitles(for item: Item, tone: TitleTone) async throws -> [ListingText] {
        let request = TitleRequest(
            itemId: item.id,
            tone: tone,
            brand: item.brand,
            size: item.size,
            material: item.material,
            condition: item.condition.rawValue,
            aspects: item.aspects
        )
        let data = try JSONEncoder.apiEncoder.encode(request)
        let endpoint = Endpoint(path: "/titles/generate", method: "POST", body: data)
        return try await httpClient.request(endpoint, decodeTo: [ListingText].self)
    }
}

private struct TitleRequest: Codable {
    var itemId: UUID
    var tone: TitleTone
    var brand: String
    var size: String
    var material: String
    var condition: String
    var aspects: [Aspect]
}
