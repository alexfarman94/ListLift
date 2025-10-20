import Foundation

struct Account: Codable {
    var userId: UUID
    var plan: SubscriptionPlan
    var quotas: Quotas
    var ebayAuth: EbayAuth?
    var templates: [Template]
    var policiesCache: PoliciesCache

    struct Quotas: Codable {
        var processedListings: Int
        var processedListingsLimit: Int

        var remaining: Int { processedListingsLimit - processedListings }
    }
}

struct EbayAuth: Codable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var scope: [String]
    var siteId: String
}

struct Template: Identifiable, Codable {
    var id: UUID
    var name: String
    var categoryId: String
    var defaults: [Aspect]
    var tone: TitleTone
}

struct PoliciesCache: Codable {
    var shippingPolicies: [Policy]
    var paymentPolicies: [Policy]
    var returnPolicies: [Policy]
}

struct Policy: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var marketplaceId: String
}

enum SubscriptionPlan: String, Codable, CaseIterable, Identifiable {
    case free
    case pro
    case power

    var id: String { rawValue }

    var monthlyPrice: Decimal {
        switch self {
        case .free: return 0
        case .pro: return 9.99
        case .power: return 24.99
        }
    }

    var listingLimit: Int {
        switch self {
        case .free: return 10
        case .pro: return 200
        case .power: return Int.max
        }
    }
}
