import SwiftUI
import StoreKit

struct PaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var purchases = PurchaseManager.shared
    @State private var purchasing: String? = nil
    @State private var error: String? = nil

    var body: some View {
        ZStack {
            Color("ParchmentBackground").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Text("🕯️")
                        .font(.system(size: 56))
                        .padding(.top, 24)

                    Text("Bill is waiting for you.")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(Color("LexiconText"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Text("Your 3 free conversations are up. A subscription keeps his light on.")
                        .font(.system(.body, design: .serif))
                        .italic()
                        .foregroundStyle(Color("SaddleBrown"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        ForEach(purchases.products, id: \.id) { product in
                            PaywallPricingCard(
                                product: product,
                                isMostPopular: product.id.contains("monthly"),
                                savings: product.id.contains("yearly") ? "Save 62%" : nil,
                                isPurchasing: purchasing == product.id
                            ) {
                                await buy(product)
                            }
                        }
                        if purchases.products.isEmpty {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding(.horizontal, 24)

                    if let error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color("CrisisRed"))
                            .padding(.horizontal, 24)
                    }

                    Button {
                        Task {
                            do {
                                try await purchases.restorePurchases()
                                if purchases.isSubscribed {
                                    appState.isSubscribed = true
                                    dismiss()
                                }
                            } catch {
                                self.error = error.localizedDescription
                            }
                        }
                    } label: {
                        Text("Restore Purchases")
                            .font(.footnote)
                            .foregroundStyle(Color("SaddleBrown"))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                }
            }
        }
        .task {
            if purchases.products.isEmpty { await purchases.loadProducts() }
        }
    }

    private func buy(_ product: Product) async {
        error = nil
        purchasing = product.id
        defer { purchasing = nil }
        do {
            let ok = try await purchases.purchase(product)
            if ok {
                appState.isSubscribed = true
                dismiss()
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct PaywallPricingCard: View {
    let product: Product
    let isMostPopular: Bool
    let savings: String?
    let isPurchasing: Bool
    let onTap: () async -> Void

    var body: some View {
        Button {
            Task { await onTap() }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(Color("LexiconText"))
                        if isMostPopular {
                            Text("MOST POPULAR")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color("AmberAccent"))
                                .clipShape(Capsule())
                        }
                    }
                    if let savings {
                        Text(savings)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color("AmberAccent"))
                    }
                }
                Spacer()
                if isPurchasing {
                    ProgressView()
                } else {
                    Text(product.displayPrice)
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(Color("LexiconText"))
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color("OldPaper")))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isMostPopular ? Color("AmberAccent") : Color("AgedGold"),
                            lineWidth: isMostPopular ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }
}
