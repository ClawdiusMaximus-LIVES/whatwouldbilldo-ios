import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var purchases = PurchaseManager.shared
    @State private var purchaseMessage: String? = nil

    var body: some View {
        NavigationStack {
            List {
                Section("Journey") {
                    if let date = appState.sobrietyDate {
                        LabeledContent("Sobriety Date", value: date.formatted(date: .abbreviated, time: .omitted))
                    } else {
                        Text("Sobriety date not set")
                            .foregroundStyle(Color("SaddleBrown"))
                    }
                }

                Section("S3 — StoreKit verification") {
                    Button {
                        Task { await purchases.loadProducts() }
                    } label: {
                        HStack {
                            Text(purchases.isLoadingProducts ? "Loading…" : "Load Products")
                            Spacer()
                            if purchases.isLoadingProducts {
                                ProgressView()
                            }
                        }
                    }

                    if purchases.products.isEmpty {
                        Text("Tap Load Products to fetch from StoreKit config.")
                            .font(.footnote)
                            .foregroundStyle(Color("SaddleBrown"))
                    } else {
                        ForEach(purchases.products, id: \.id) { product in
                            Button {
                                Task { await attemptPurchase(product) }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(product.displayName).bold()
                                        Spacer()
                                        Text(product.displayPrice)
                                    }
                                    Text(product.id)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(Color("LexiconText"))
                        }
                    }

                    LabeledContent("Subscribed", value: purchases.isSubscribed ? "yes" : "no")
                    if let id = purchases.activeProductID {
                        LabeledContent("Active plan", value: id)
                    }

                    Button("Restore Purchases") {
                        Task {
                            do { try await purchases.restorePurchases() }
                            catch { purchaseMessage = "Restore failed: \(error.localizedDescription)" }
                        }
                    }

                    if let msg = purchaseMessage {
                        Text(msg)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    if let err = purchases.lastError {
                        Text("Load error: \(err)")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section("About") {
                    Text("Full settings tab is built in S7.")
                        .font(.caption)
                        .foregroundStyle(Color("SaddleBrown"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("ParchmentBackground"))
            .navigationTitle("Settings")
            .task {
                await purchases.loadProducts()
                await purchases.updateSubscriptionStatus()
            }
        }
    }

    private func attemptPurchase(_ product: Product) async {
        purchaseMessage = nil
        do {
            let ok = try await purchases.purchase(product)
            purchaseMessage = ok ? "Purchased \(product.displayName) ✓" : "Purchase not completed."
        } catch {
            purchaseMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
