import SwiftUI
import PhotosUI

struct ListingEditorView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel: ListingViewModel
    @StateObject private var compsViewModel: CompsViewModel
    @State private var presentTitleGenerator = false
    @State private var presentExportSheet = false
    @State private var selectedMarketplace: ExportMarketplace = .depop

    init(item: Item) {
        let vm = ListingViewModel(item: item)
        _viewModel = StateObject(wrappedValue: vm)
        _compsViewModel = StateObject(wrappedValue: CompsViewModel(itemProvider: { vm.item }))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                photoSection
                attributesSection
                categorySection
                aspectsSection
                pricingSection
                titleSection
                publishSection
                exportSection
            }
            .padding()
        }
        .navigationTitle("Listing")
        .toolbar { toolbarContent }
        .alert(isPresented: Binding(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
            Alert(title: Text("Oops"), message: Text(viewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $presentTitleGenerator) {
            TitleGeneratorView(item: viewModel.item)
                .environmentObject(environment)
        }
        .sheet(isPresented: $presentExportSheet) {
            ExportSheetView(item: viewModel.item, marketplace: $selectedMarketplace)
                .environmentObject(environment)
        }
        .task {
            viewModel.configure(with: environment)
            compsViewModel.configure(with: environment)
            await compsViewModel.fetch()
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading) {
            HeaderView(title: "Photos", subtitle: "Clean backgrounds and crop automatically")
            PhotoPickerGrid(photos: viewModel.item.cleanedPhotos) { data in
                await viewModel.addPhoto(data)
            }
            if viewModel.isProcessingPhotos {
                ProgressView("Processing…")
            }
        }
    }

    private var attributesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeaderView(title: "Attributes", subtitle: "Extracted from labels with Vision OCR")
            TextField("Brand", text: Binding(get: { viewModel.item.brand }, set: { viewModel.item.brand = $0 }))
                .textFieldStyle(.roundedBorder)
            TextField("Size", text: Binding(get: { viewModel.item.size }, set: { viewModel.item.size = $0 }))
                .textFieldStyle(.roundedBorder)
            TextField("Material", text: Binding(get: { viewModel.item.material }, set: { viewModel.item.material = $0 }))
                .textFieldStyle(.roundedBorder)
            Text("Confidence: \(viewModel.ocrConfidence, format: .percent)")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeaderView(title: "Category", subtitle: "Required before publish")
            if viewModel.categorySuggestions.isEmpty {
                Button("Get suggestions") {
                    Task { await viewModel.loadCategories() }
                }
            } else {
                ForEach(viewModel.categorySuggestions) { suggestion in
                    Button(action: { Task { await viewModel.selectCategory(suggestion) } }) {
                        HStack {
                            Text(suggestion.categoryPath)
                            Spacer()
                            if viewModel.item.categoryId == suggestion.categoryId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        }
    }

    private var aspectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeaderView(title: "Item specifics", subtitle: "Complete all required fields")
            ForEach(Array(viewModel.item.aspects.enumerated()), id: \.element.id) { index, aspect in
                VStack(alignment: .leading) {
                    Text(aspect.name + (aspect.isRequired ? " *" : ""))
                    if aspect.options.isEmpty {
                        TextField("Enter \(aspect.name.lowercased())", text: Binding(
                            get: { viewModel.item.aspects[index].value },
                            set: {
                                viewModel.item.aspects[index].value = $0
                                Task { await viewModel.updateAspect(viewModel.item.aspects[index]) }
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                    } else {
                        Picker(aspect.name, selection: Binding(
                            get: { viewModel.item.aspects[index].value },
                            set: {
                                viewModel.item.aspects[index].value = $0
                                Task { await viewModel.updateAspect(viewModel.item.aspects[index]) }
                            }
                        )) {
                            ForEach(aspect.options, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
        }
    }

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeaderView(title: "Price", subtitle: "Median and IQR from comps")
            if let summary = compsViewModel.pricingSummary {
                PriceCard(summary: summary)
            }
            Button("Refresh comps") {
                Task { await compsViewModel.fetch() }
            }
            TextField("Your price", value: Binding(
                get: { viewModel.item.priceSet as NSDecimalNumber? },
                set: { newValue in
                    if let value = newValue {
                        Task { await viewModel.setPrice(value as Decimal) }
                    }
                }
            ), formatter: NumberFormatter.currencyGBP)
            .textFieldStyle(.roundedBorder)
            .keyboardType(.decimalPad)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeaderView(title: "Title & description", subtitle: "Choose from AI generated variants")
            if viewModel.item.titleOptions.isEmpty {
                Button("Generate variants") { presentTitleGenerator = true }
            } else {
                ForEach(viewModel.item.titleOptions) { option in
                    Button(action: { Task { await viewModel.updateTitleSelection(option.id) } }) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(option.title)
                                Spacer()
                                if viewModel.item.selectedTitleId == option.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                            Text(option.description)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var publishSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeaderView(title: "Publish to eBay", subtitle: "Select policies and publish")
            PublishControlsView(item: viewModel.item)
                .environmentObject(environment)
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HeaderView(title: "Export kits", subtitle: "Speed listing on other marketplaces")
            Picker("Marketplace", selection: $selectedMarketplace) {
                ForEach(ExportMarketplace.allCases) { marketplace in
                    Text(marketplace.displayName).tag(marketplace)
                }
            }
            .pickerStyle(.menu)
            Button("Generate export kit") {
                presentExportSheet = true
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}

struct HeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(subtitle).font(.subheadline).foregroundColor(.secondary)
        }
    }
}

struct PhotoPickerGrid: View {
    let photos: [PhotoAsset]
    var onPick: (Data) async -> Void
    @State private var pickerPresented = false
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(photos) { photo in
                if let url = photo.cleanedURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(12)
                }
            }
            PhotosPicker(selection: $selectedItems, matching: .images) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .frame(width: 100, height: 100)
                    Image(systemName: "plus")
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            await onPick(data)
                        }
                    }
                    selectedItems = []
                }
            }
        }
    }
}

struct PriceCard: View {
    let summary: PricingSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Median £\(summary.priceBand.median as NSDecimalNumber, formatter: NumberFormatter.currencyGBP)")
                .font(.title2)
            Text("IQR £\(summary.priceBand.iqr as NSDecimalNumber, formatter: NumberFormatter.currencyGBP)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Confidence: \(summary.priceBand.confidence.rawValue.capitalized)")
                .font(.subheadline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(summary.items) { item in
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.caption)
                                .lineLimit(2)
                            Text("£\(item.price as NSDecimalNumber, formatter: NumberFormatter.currencyGBP)")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}
