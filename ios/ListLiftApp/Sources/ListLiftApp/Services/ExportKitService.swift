import Foundation
import UIKit

actor ExportKitService {
    func generateExportPackage(for item: Item, marketplace: ExportMarketplace) async throws -> ExportPackage {
        let resizedImages = try await resizeImages(item.cleanedPhotos, marketplace: marketplace)
        let title = item.selectedTitle?.title ?? item.brand
        let description = item.selectedTitle?.description ?? item.description
        let specifics = item.aspects.map { "\($0.name): \($0.value)" }.joined(separator: "\n")
        let checklist = checklist(for: marketplace)
        return ExportPackage(
            marketplace: marketplace,
            images: resizedImages,
            title: title,
            description: description,
            specifics: specifics,
            checklist: checklist
        )
    }

    private func resizeImages(_ photos: [PhotoAsset], marketplace: ExportMarketplace) async throws -> [Data] {
        try await withThrowingTaskGroup(of: Data.self) { group in
            for photo in photos {
                guard let url = photo.cleanedURL, let data = try? Data(contentsOf: url) else { continue }
                group.addTask {
                    return try await self.resize(data: data, targetSize: marketplace.preferredSize)
                }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }
    }

    private func resize(data: Data, targetSize: CGSize) async throws -> Data {
        guard let image = UIImage(data: data) else { throw ExportError.invalidImage }
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let output = renderer.jpegData(withCompressionQuality: 0.9) { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        guard let output else { throw ExportError.invalidImage }
        return output
    }

    private func checklist(for marketplace: ExportMarketplace) -> [String] {
        switch marketplace {
        case .depop:
            return ["Open Depop app", "Tap Sell", "Upload resized photos", "Paste title & description", "Set price", "Publish"]
        case .vinted:
            return ["Open Vinted", "Tap Sell", "Upload resized photos", "Paste title", "Fill brand & size", "Set shipping", "Publish"]
        case .poshmark:
            return ["Open Poshmark", "Tap Sell", "Upload resized photos", "Paste description", "Set price", "List"]
        case .mercari:
            return ["Open Mercari", "Add photos", "Paste details", "Set shipping", "List"]
        case .facebookMarketplace:
            return ["Open Facebook Marketplace", "Tap Sell", "Upload photos", "Paste title", "Paste description", "Set price", "Post"]
        }
    }

    enum ExportError: Error {
        case invalidImage
    }
}

struct ExportPackage: Codable {
    var marketplace: ExportMarketplace
    var images: [Data]
    var title: String
    var description: String
    var specifics: String
    var checklist: [String]
}

private extension ExportMarketplace {
    var preferredSize: CGSize {
        switch self {
        case .depop, .vinted: return CGSize(width: 1080, height: 1350)
        case .poshmark: return CGSize(width: 1200, height: 1600)
        case .mercari: return CGSize(width: 1080, height: 1080)
        case .facebookMarketplace: return CGSize(width: 1200, height: 900)
        }
    }
}
