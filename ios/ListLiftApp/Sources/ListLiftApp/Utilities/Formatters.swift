import Foundation

extension NumberFormatter {
    static var currencyGBP: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter
    }
}
