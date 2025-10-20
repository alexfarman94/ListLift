import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var items: [Item] = []
    @State private var account: Account?
    @State private var presentNewListing = false

    var body: some View {
        NavigationStack {
            List {
                if let account {
                    Section("Plan") {
                        VStack(alignment: .leading) {
                            Text(account.plan.rawValue.capitalized)
                                .font(.headline)
                            Text("\(account.quotas.processedListings) of \(account.quotas.processedListingsLimit) processed this month")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section("Your listings") {
                    ForEach(items) { item in
                        NavigationLink(destination: ListingEditorView(item: item).environmentObject(environment)) {
                            ListingRowView(item: item)
                        }
                    }
                }
            }
            .navigationTitle("ListLift")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { presentNewListing = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .task {
                await reload()
            }
            .sheet(isPresented: $presentNewListing, onDismiss: {
                Task { await reload() }
            }) {
                NavigationStack {
                    ListingEditorView(item: .empty)
                        .environmentObject(environment)
                }
            }
        }
    }

    private func reload() async {
        items = await environment.dataStore.getItems().sorted(by: { $0.updatedAt > $1.updatedAt })
        account = await environment.dataStore.getAccount()
    }
}

struct ListingRowView: View {
    let item: Item

    var body: some View {
        HStack {
            if let data = item.cleanedPhotos.first?.thumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 56, height: 56)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 56, height: 56)
            }
            VStack(alignment: .leading) {
                Text(item.selectedTitle?.title ?? "Untitled")
                    .font(.headline)
                Text(item.marketplaceStatus.ebay == .published ? "Published" : "Draft")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let price = item.priceSet {
                Text("£\(price as NSDecimalNumber, formatter: NumberFormatter.currencyGBP)")
                    .font(.headline)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Listing \(item.selectedTitle?.title ?? "Untitled"), status \(item.marketplaceStatus.ebay.rawValue)")
    }
}
