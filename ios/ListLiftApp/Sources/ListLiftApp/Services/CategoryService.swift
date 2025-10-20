import Foundation

actor CategoryService {
    struct CategorySuggestion: Codable, Identifiable {
        var id: String { categoryId }
        let categoryId: String
        let categoryPath: String
        let confidence: Double
    }

    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func suggestions(for item: Item) async throws -> [CategorySuggestion] {
        let body = SuggestionRequest(title: item.selectedTitle?.title ?? item.brand, aspects: item.aspects)
        let data = try JSONEncoder.apiEncoder.encode(body)
        let endpoint = Endpoint(path: "/categories/suggest", method: "POST", body: data)
        return try await httpClient.request(endpoint, decodeTo: [CategorySuggestion].self)
    }

    func specifics(for categoryId: String) async throws -> [Aspect] {
        let endpoint = Endpoint(path: "/categories/\(categoryId)/specifics")
        return try await httpClient.request(endpoint, decodeTo: [Aspect].self)
    }

    private struct SuggestionRequest: Codable {
        let title: String
        let aspects: [Aspect]
    }
}
