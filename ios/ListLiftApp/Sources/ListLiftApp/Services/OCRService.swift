import Foundation
import Vision
import UIKit

actor OCRService {
    struct OCRResult {
        var brand: String
        var size: String
        var material: String
        var confidence: Double
    }

    func extractAttributes(from imageData: Data) async throws -> OCRResult {
        let requestHandler = VNImageRequestHandler(data: imageData, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["en-GB", "en-US"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        try requestHandler.perform([request])
        guard let observations = request.results else {
            return OCRResult(brand: "", size: "", material: "", confidence: 0)
        }

        let text = observations.compactMap { $0.topCandidates(1).first?.string.uppercased() }
        let brand = text.first(where: { $0.containsLettersOnly && $0.count >= 3 }) ?? ""
        let size = text.first(where: { $0.matchesSizePattern }) ?? ""
        let material = text.first(where: { $0.containsMaterialKeyword }) ?? ""

        let confidences = observations.map { $0.topCandidates(1).first?.confidence ?? 0 }
        let averageConfidence = confidences.reduce(0, +) / Double(max(confidences.count, 1))

        return OCRResult(brand: brand.capitalized, size: size, material: material.capitalized, confidence: averageConfidence)
    }
}

private extension String {
    var containsLettersOnly: Bool {
        let letters = CharacterSet.letters
        return rangeOfCharacter(from: letters.inverted) == nil
    }

    var matchesSizePattern: Bool {
        range(of: "^(UK|US|EU)?\\s?([0-9]{1,2}|[XSML]{1,3})(/([0-9]{1,2}))?$", options: .regularExpression) != nil
    }

    var containsMaterialKeyword: Bool {
        let materials = ["COTTON", "POLYESTER", "LEATHER", "WOOL", "DENIM", "SILK", "LINEN"]
        return materials.contains(where: { contains($0) })
    }
}
