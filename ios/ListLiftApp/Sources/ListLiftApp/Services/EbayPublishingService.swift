import Foundation
import AuthenticationServices

actor EbayPublishingService: NSObject {
    private let httpClient: HTTPClient
    private let dataStore: DataStore
    private var continuation: CheckedContinuation<EbayAuth, Error>?

    init(httpClient: HTTPClient, dataStore: DataStore) {
        self.httpClient = httpClient
        self.dataStore = dataStore
    }

    func signIn(contextProvider: ASWebAuthenticationPresentationContextProviding) async throws -> EbayAuth {
        let callbackURLScheme = "listlift"
        let authURL = URL(string: "https://auth.ebay.com/oauth2/authorize?client_id=LISTLIFT&response_type=code&redirect_uri=listlift://auth")!

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackURLScheme) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let url = callbackURL, let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: PublishError.invalidCallback)
                    return
                }
                Task {
                    do {
                        let auth = try await self.exchangeCodeForToken(code: code)
                        continuation.resume(returning: auth)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            session.presentationContextProvider = contextProvider
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
    }

    private func exchangeCodeForToken(code: String) async throws -> EbayAuth {
        struct TokenResponse: Codable {
            var accessToken: String
            var refreshToken: String
            var expiresIn: Int
            var scope: String
            var refreshTokenExpiresIn: Int
        }
        let body = ["code": code]
        let data = try JSONEncoder.apiEncoder.encode(body)
        let endpoint = Endpoint(path: "/ebay/oauth/token", method: "POST", body: data)
        let token = try await httpClient.request(endpoint, decodeTo: TokenResponse.self)
        let auth = EbayAuth(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(token.expiresIn)),
            scope: token.scope.components(separatedBy: " "),
            siteId: "EBAY_GB"
        )
        var account = await dataStore.getAccount()
        account.ebayAuth = auth
        await dataStore.saveAccount(account)
        return auth
    }

    func publish(item: Item, offer: PublishOffer) async throws -> PublishResult {
        guard await dataStore.getAccount().ebayAuth != nil else {
            throw PublishError.notAuthenticated
        }
        let request = PublishRequest(item: item, offer: offer)
        let data = try JSONEncoder.apiEncoder.encode(request)
        let endpoint = Endpoint(path: "/ebay/publish", method: "POST", body: data)
        return try await httpClient.request(endpoint, decodeTo: PublishResult.self)
    }

    func refreshTokenIfNeeded() async throws {
        guard var account = await dataStore.getAccount().ebayAuth else { return }
        if account.expiresAt.timeIntervalSinceNow > 300 { return }
        let body = ["refreshToken": account.refreshToken]
        let data = try JSONEncoder.apiEncoder.encode(body)
        let endpoint = Endpoint(path: "/ebay/oauth/refresh", method: "POST", body: data)
        let refreshed = try await httpClient.request(endpoint, decodeTo: EbayAuth.self)
        var acc = await dataStore.getAccount()
        acc.ebayAuth = refreshed
        await dataStore.saveAccount(acc)
    }

    enum PublishError: Error {
        case notAuthenticated
        case invalidCallback
    }
}

struct PublishOffer: Codable {
    var price: Double
    var quantity: Int
    var shippingPolicyId: String
    var paymentPolicyId: String
    var returnPolicyId: String
}

struct PublishResult: Codable {
    var listingId: String
    var listingURL: URL
    var status: String
}

private struct PublishRequest: Codable {
    var item: Item
    var offer: PublishOffer
}
