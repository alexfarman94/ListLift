import Foundation
import SwiftUI

@MainActor
final class ListingViewModel: ObservableObject {
    @Published var item: Item
    @Published var categorySuggestions: [CategoryService.CategorySuggestion] = []
    @Published var ocrConfidence: Double = 0
    @Published var isProcessingPhotos = false
    @Published var errorMessage: String?

    private var dataStore: DataStore?
    private var photoService: PhotoProcessingService?
    private var ocrService: OCRService?
    private var categoryService: CategoryService?
    private var billingService: BillingService?
    private var analytics: AnalyticsService?

    init(item: Item = .empty) {
        self.item = item
    }

    func configure(with environment: AppEnvironment) {
        self.dataStore = environment.dataStore
        self.photoService = environment.photoService
        self.ocrService = environment.ocrService
        self.categoryService = environment.categoryService
        self.billingService = environment.billingService
        self.analytics = environment.analyticsService
    }

    func addPhoto(_ data: Data) async {
        guard let photoService, let billingService else { return }
        isProcessingPhotos = true
        defer { isProcessingPhotos = false }
        do {
            let enhanced = try await photoService.autoEnhance(imageData: data)
            let (cleaned, confidence) = try await photoService.removeBackground(from: enhanced)
            let cropped = try await photoService.autoCropToSquare(imageData: cleaned)
            try await billingService.trackProcessedListing()
            analytics?.track(.photoCleaned)
            let photo = PhotoAsset(originalURL: nil, cleanedURL: try await saveImage(cropped), metadata: .init(backgroundConfidence: confidence))
            item.photos.append(photo)
            item.cleanedPhotos.append(photo)
            await persist()
        } catch BillingService.BillingError.quotaExceeded {
            errorMessage = "You have reached your plan limit. Upgrade to continue."
        } catch {
            errorMessage = "Photo processing failed. Try again."
        }
    }

    func runOCR(on data: Data) async {
        guard let ocrService else { return }
        do {
            let result = try await ocrService.extractAttributes(from: data)
            item.brand = result.brand
            item.size = result.size
            item.material = result.material
            ocrConfidence = result.confidence
            analytics?.track(.ocrConfirmed, properties: ["confidence": result.confidence])
            await persist()
        } catch {
            errorMessage = "Label recognition failed."
        }
    }

    func loadCategories() async {
        guard let categoryService else { return }
        do {
            categorySuggestions = try await categoryService.suggestions(for: item)
        } catch {
            errorMessage = "Unable to fetch categories."
        }
    }

    func selectCategory(_ suggestion: CategoryService.CategorySuggestion) async {
        guard let categoryService else { return }
        item.categoryId = suggestion.categoryId
        do {
            item.aspects = try await categoryService.specifics(for: suggestion.categoryId)
            analytics?.track(.categoryConfirmed, properties: ["category": suggestion.categoryPath])
            await persist()
        } catch {
            errorMessage = "Failed to load item specifics."
        }
    }

    func updateAspect(_ aspect: Aspect) async {
        guard let dataStore else { return }
        guard let index = item.aspects.firstIndex(where: { $0.id == aspect.id }) else { return }
        item.aspects[index] = aspect
        await dataStore.upsert(item)
    }

    func updateTitleSelection(_ id: UUID?) async {
        item.selectedTitleId = id
        await persist()
    }

    func setPrice(_ price: Decimal) async {
        item.priceSet = price
        analytics?.track(.priceSet, properties: ["price": price])
        await persist()
    }

    private func persist() async {
        guard let dataStore else { return }
        item.updatedAt = Date()
        await dataStore.upsert(item)
    }

    private func saveImage(_ data: Data) async throws -> URL {
        let directory = FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent("\(UUID().uuidString).jpg")
        try data.write(to: url)
        return url
    }
}
