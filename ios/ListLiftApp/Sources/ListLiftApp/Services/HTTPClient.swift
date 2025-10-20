import Foundation

struct HTTPClient {
    enum HTTPError: Error {
        case invalidResponse
        case decodingFailed
        case serverError(status: Int, message: String)
    }

    func request<T: Decodable>(_ endpoint: Endpoint, decodeTo: T.Type = T.self) async throws -> T {
        var urlRequest = URLRequest(url: endpoint.url)
        urlRequest.httpMethod = endpoint.method
        endpoint.headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        urlRequest.httpBody = endpoint.body

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw HTTPError.serverError(status: httpResponse.statusCode, message: message)
        }
        do {
            return try JSONDecoder.apiDecoder.decode(T.self, from: data)
        } catch {
            throw HTTPError.decodingFailed
        }
    }
}

struct Endpoint {
    var path: String
    var method: String = "GET"
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = ["Content-Type": "application/json"]
    var body: Data?

    var url: URL {
        var components = URLComponents()
        components.scheme = Environment.current.scheme
        components.host = Environment.current.host
        components.port = Environment.current.port
        components.path = "/api" + path
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        return components.url!
    }
}

struct Environment {
    static var current = Environment()

    var scheme: String = "https"
    var host: String = "api.listlift.app"
    var port: Int?
}

extension JSONDecoder {
    static var apiDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

extension JSONEncoder {
    static var apiEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
