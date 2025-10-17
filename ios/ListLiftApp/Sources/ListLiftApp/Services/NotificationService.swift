import Foundation
import UserNotifications

actor NotificationService {
    private let dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    func registerForRemoteNotifications() async {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
        if granted == true {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func handleSaleNotification(_ notification: SaleNotification) async {
        var items = await dataStore.getItems()
        guard let index = items.firstIndex(where: { $0.id == notification.itemId }) else { return }
        var item = items[index]
        item.marketplaceStatus.ebay = .sold
        items[index] = item
        await dataStore.saveItems(items)
    }
}

struct SaleNotification: Codable {
    var itemId: UUID
    var orderId: String
    var soldAt: Date
}
