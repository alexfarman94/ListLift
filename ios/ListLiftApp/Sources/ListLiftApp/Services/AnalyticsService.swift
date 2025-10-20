import Foundation

actor AnalyticsService {
    enum Event: String {
        case photoCleaned
        case ocrConfirmed
        case categoryConfirmed
        case compsViewed
        case priceSet
        case publishedSuccess
        case exportUsed
        case saleDetected
    }

    nonisolated func track(_ event: Event, properties: [String: Any] = [:]) {
        print("[Analytics] \(event.rawValue): \(properties)")
    }
}
