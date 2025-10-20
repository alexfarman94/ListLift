import SwiftUI

struct ExportSheetView: View {
    @EnvironmentObject private var environment: AppEnvironment
    let item: Item
    @Binding var marketplace: ExportMarketplace
    @State private var exportPackage: ExportPackage?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Marketplace", selection: $marketplace) {
                    ForEach(ExportMarketplace.allCases) { marketplace in
                        Text(marketplace.displayName).tag(marketplace)
                    }
                }
                .pickerStyle(.segmented)

                if isLoading {
                    ProgressView("Preparing export kit…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let exportPackage {
                    List {
                        Section("Title & description") {
                            Text(exportPackage.title)
                            Text(exportPackage.description)
                                .font(.footnote)
                        }
                        Section("Item specifics") {
                            Text(exportPackage.specifics)
                                .font(.footnote)
                        }
                        Section("Checklist") {
                            ForEach(exportPackage.checklist, id: \.self) { step in
                                Text(step)
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Export kit")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Copy text") {
                        UIPasteboard.general.string = [exportPackage?.title, exportPackage?.description, exportPackage?.specifics].compactMap { $0 }.joined(separator: "\n\n")
                    }
                    .disabled(exportPackage == nil)
                }
            }
        }
        .task(id: marketplace) {
            await generate()
        }
    }

    private func generate() async {
        isLoading = true
        defer { isLoading = false }
        do {
            exportPackage = try await environment.exportService.generateExportPackage(for: item, marketplace: marketplace)
            environment.analyticsService.track(.exportUsed, properties: ["marketplace": marketplace.rawValue])
        } catch {
            exportPackage = nil
        }
    }
}
