import SwiftUI

struct TitleGeneratorView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TitleGenerationViewModel

    init(item: Item) {
        _viewModel = StateObject(wrappedValue: TitleGenerationViewModel(item: item))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Tone", selection: $viewModel.selectedTone) {
                    ForEach(TitleTone.allCases) { tone in
                        Text(tone.displayName).tag(tone)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.isLoading {
                    ProgressView("Generating…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.options) { option in
                        Button(action: {
                            Task {
                                await viewModel.choose(option: option)
                                dismiss()
                            }
                        }) {
                            VStack(alignment: .leading) {
                                Text(option.title)
                                    .font(.headline)
                                Text(option.description)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Title variants")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Generate") {
                        Task { await viewModel.generate() }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task {
            viewModel.configure(with: environment)
            if viewModel.options.isEmpty {
                await viewModel.generate()
            }
        }
    }
}
