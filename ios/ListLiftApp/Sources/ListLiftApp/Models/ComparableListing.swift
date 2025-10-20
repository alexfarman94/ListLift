import Foundation

struct ComparableListing: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var price: Decimal
    var currency: String
    var imageURL: URL?
    var url: URL
    var condition: String
    var sellerLocation: String
    var shippingCost: Decimal?
    var marketplace: String
}

struct PricingSummary: Codable {
    var items: [ComparableListing]
    var priceBand: PriceBand
}
