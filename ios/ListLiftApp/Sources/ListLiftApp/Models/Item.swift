import Foundation
import SwiftUI

struct Item: Identifiable, Codable, Equatable {
    var id: UUID
    var photos: [PhotoAsset]
    var cleanedPhotos: [PhotoAsset]
    var brand: String
    var size: String
    var material: String
    var condition: Condition
    var measurements: [Measurement]
    var categoryId: String?
    var aspects: [Aspect]
    var titleOptions: [ListingText]
    var selectedTitleId: UUID?
    var description: String
    var priceSuggested: PriceBand?
    var priceSet: Decimal?
    var marketplaceStatus: MarketplaceStatus
    var createdAt: Date
    var updatedAt: Date

    static let empty = Item(
        id: UUID(),
        photos: [],
        cleanedPhotos: [],
        brand: "",
        size: "",
        material: "",
        condition: .preOwned,
        measurements: [],
        categoryId: nil,
        aspects: [],
        titleOptions: [],
        selectedTitleId: nil,
        description: "",
        priceSuggested: nil,
        priceSet: nil,
        marketplaceStatus: MarketplaceStatus(),
        createdAt: Date(),
        updatedAt: Date()
    )

    var selectedTitle: ListingText? {
        titleOptions.first(where: { $0.id == selectedTitleId })
    }

    var requiredAspectsComplete: Bool {
        aspects.filter { $0.isRequired }.allSatisfy { !$0.value.isEmpty }
    }
}

struct Measurement: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var value: String
}

struct MarketplaceStatus: Codable, Equatable {
    var ebay: Status
    var etsy: Status
    var exports: [ExportStatus]

    init(ebay: Status = .draft, etsy: Status = .draft, exports: [ExportStatus] = []) {
        self.ebay = ebay
        self.etsy = etsy
        self.exports = exports
    }

    enum Status: String, Codable {
        case draft
        case published
        case sold
        case archived
    }
}

struct ExportStatus: Identifiable, Codable, Equatable {
    var id: UUID
    var marketplace: ExportMarketplace
    var lastExportedAt: Date?
}

enum ExportMarketplace: String, Codable, CaseIterable, Identifiable {
    case depop
    case vinted
    case poshmark
    case mercari
    case facebookMarketplace

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .depop: return "Depop"
        case .vinted: return "Vinted"
        case .poshmark: return "Poshmark"
        case .mercari: return "Mercari"
        case .facebookMarketplace: return "Facebook Marketplace"
        }
    }
}

struct ListingText: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var description: String
    var tone: TitleTone
    var qualityScore: Double
}

enum TitleTone: String, Codable, CaseIterable, Identifiable {
    case seo
    case concise
    case vintage

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .seo: return "SEO (Long)"
        case .concise: return "Concise"
        case .vintage: return "Vintage"
        }
    }
}

struct Aspect: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var value: String
    var isRequired: Bool
    var options: [String]
}

enum Condition: String, Codable, CaseIterable, Identifiable {
    case newWithTags
    case newWithoutTags
    case preOwned
    case excellent
    case good
    case fair

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newWithTags: return "New (With Tags)"
        case .newWithoutTags: return "New (No Tags)"
        case .preOwned: return "Pre-owned"
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        }
    }
}

struct PriceBand: Codable, Equatable {
    var resultsCount: Int
    var median: Decimal
    var iqr: Decimal
    var suggestedMin: Decimal
    var suggestedMax: Decimal
    var confidence: Confidence

    enum Confidence: String, Codable {
        case high
        case medium
        case low
    }
}
