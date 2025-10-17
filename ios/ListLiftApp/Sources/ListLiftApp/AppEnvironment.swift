import Foundation
import Combine

@MainActor
final class AppEnvironment: ObservableObject {
    @Published var dataStore = DataStore()
    @Published var photoService: PhotoProcessingService!
    @Published var ocrService: OCRService!
    @Published var categoryService: CategoryService!
    @Published var pricingService: PricingService!
    @Published var titleService: TitleGenerationService!
    @Published var publishService: EbayPublishingService!
    @Published var exportService: ExportKitService!
    @Published var notificationService: NotificationService!
    @Published var billingService: BillingService!
    @Published var analyticsService: AnalyticsService!

    func bootstrap() async {
        if photoService != nil { return }
        let httpClient = HTTPClient()
        photoService = PhotoProcessingService()
        ocrService = OCRService()
        categoryService = CategoryService(httpClient: httpClient)
        pricingService = PricingService(httpClient: httpClient)
        titleService = TitleGenerationService(httpClient: httpClient)
        publishService = EbayPublishingService(httpClient: httpClient, dataStore: dataStore)
        exportService = ExportKitService()
        notificationService = NotificationService(dataStore: dataStore)
        billingService = BillingService(dataStore: dataStore)
        analyticsService = AnalyticsService()
        await notificationService.registerForRemoteNotifications()
    }
}
