import SwiftUI

struct PublishControlsView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var viewModel: PublishViewModel
    @State private var offer = PublishOffer(price: 0, quantity: 1, shippingPolicyId: "", paymentPolicyId: "", returnPolicyId: "")
    @State private var policies = PoliciesCache(shippingPolicies: [], paymentPolicies: [], returnPolicies: [])
    @State private var showResult = false

    init(item: Item) {
        _viewModel = StateObject(wrappedValue: PublishViewModel(item: item))
        _offer = State(initialValue: PublishOffer(price: item.priceSet ?? 0, quantity: 1, shippingPolicyId: "", paymentPolicyId: "", returnPolicyId: ""))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Price", value: $offer.price, formatter: NumberFormatter.currencyGBP)
                .textFieldStyle(.roundedBorder)
            Stepper("Quantity: \(offer.quantity)", value: $offer.quantity, in: 1...10)
            PolicyPicker(title: "Shipping policy", policies: policies.shippingPolicies, selection: $offer.shippingPolicyId)
            PolicyPicker(title: "Payment policy", policies: policies.paymentPolicies, selection: $offer.paymentPolicyId)
            PolicyPicker(title: "Return policy", policies: policies.returnPolicies, selection: $offer.returnPolicyId)
            Button(action: {
                Task {
                    viewModel.configureIfNeeded(environment: environment)
                    await viewModel.publish(offer: offer)
                    showResult = true
                }
            }) {
                if viewModel.isPublishing {
                    ProgressView()
                } else {
                    Text("Publish to eBay")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canPublish)
        }
        .task {
            viewModel.configureIfNeeded(environment: environment)
            let account = await environment.dataStore.getAccount()
            policies = account.policiesCache
        }
        .alert("Publish status", isPresented: $showResult, presenting: viewModel.publishResult) { _ in
            Button("OK", role: .cancel) { }
        } message: { result in
            Text(result?.status ?? viewModel.errorMessage ?? "Unknown result")
        }
    }

    private var canPublish: Bool {
        !offer.shippingPolicyId.isEmpty && !offer.paymentPolicyId.isEmpty && !offer.returnPolicyId.isEmpty
    }
}

struct PolicyPicker: View {
    let title: String
    let policies: [Policy]
    @Binding var selection: String

    var body: some View {
        Picker(title, selection: $selection) {
            Text("Select")
                .tag("")
            ForEach(policies) { policy in
                Text(policy.name).tag(policy.id)
            }
        }
        .pickerStyle(.menu)
    }
}
