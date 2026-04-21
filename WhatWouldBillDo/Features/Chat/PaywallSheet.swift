import SwiftUI
import StoreKit

struct PaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var purchases = PurchaseManager.shared
    @State private var selectedProductID: String? = nil
    @State private var purchasing: Bool = false
    @State private var error: String? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color("DarkBackground").ignoresSafeArea()

            // Warm glow backdrop behind the candle
            RadialGradient(
                gradient: Gradient(colors: [
                    Color("AmberAccent").opacity(0.35),
                    Color("AmberAccent").opacity(0.0)
                ]),
                center: UnitPoint(x: 0.5, y: 0.18),
                startRadius: 10,
                endRadius: 260
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 18) {
                    Spacer(minLength: 12)
                    AnimatedCandle(size: 76, onDark: true)

                    VStack(spacing: 6) {
                        Text("Bill is\nwaiting for you.")
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .foregroundStyle(Color("ParchmentBackground"))
                            .multilineTextAlignment(.center)
                            .padding(.top, -6)

                        Text("You've used your 3 free conversations. A subscription keeps the light on.")
                            .font(.system(.subheadline, design: .serif))
                            .italic()
                            .foregroundStyle(Color("ParchmentBackground").opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    VStack(spacing: 12) {
                        ForEach(orderedProducts) { product in
                            DarkPricingCard(
                                product: product,
                                isSelected: selectedProductID == product.id,
                                popular: product.id.contains("monthly"),
                                subtitleRight: subtitleRight(for: product.id),
                                savings: product.id.contains("yearly") ? "Save 62%" : nil,
                                extra: product.id.contains("yearly") ? "just $5/mo" : nil
                            ) {
                                selectedProductID = product.id
                            }
                        }
                        if purchases.products.isEmpty {
                            ProgressView().tint(.white).padding(.vertical, 16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    if let error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(Color("CrisisRed"))
                            .padding(.horizontal, 24)
                    }

                    Button(action: buySelected) {
                        HStack {
                            if purchasing { ProgressView().tint(.white) }
                            Text(purchasing ? "Processing…" : "Begin My Journey")
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(Color("LexiconText"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color("AmberAccent"))
                        .clipShape(Capsule())
                        .shadow(color: Color("AmberAccent").opacity(0.4), radius: 18, y: 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(purchasing || selectedProductID == nil)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    HStack(spacing: 20) {
                        Button("Restore") {
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
                        }
                        Link("Privacy", destination: URL(string: "https://whatwouldbilldo.com/privacy")!)
                        Link("Terms", destination: URL(string: "https://whatwouldbilldo.com/terms")!)
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .underline()
                    .foregroundStyle(Color("ParchmentBackground").opacity(0.55))
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                }
            }

            // Close button
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color("ParchmentBackground").opacity(0.75))
                    .frame(width: 34, height: 34)
                    .background(Color("ParchmentBackground").opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
        .task {
            if purchases.products.isEmpty { await purchases.loadProducts() }
            if selectedProductID == nil,
               let monthly = purchases.products.first(where: { $0.id.contains("monthly") }) {
                selectedProductID = monthly.id
            }
        }
    }

    private var orderedProducts: [Product] {
        let order = ["weekly", "monthly", "yearly"]
        return purchases.products.sorted { lhs, rhs in
            let li = order.firstIndex(where: { lhs.id.contains($0) }) ?? 99
            let ri = order.firstIndex(where: { rhs.id.contains($0) }) ?? 99
            return li < ri
        }
    }

    private func subtitleRight(for id: String) -> String {
        if id.contains("weekly") { return "/ week" }
        if id.contains("monthly") { return "/ month" }
        return ""
    }

    private func buySelected() {
        guard let id = selectedProductID,
              let product = purchases.products.first(where: { $0.id == id }) else { return }
        Task {
            error = nil
            purchasing = true
            defer { purchasing = false }
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
}

private struct DarkPricingCard: View {
    let product: Product
    let isSelected: Bool
    let popular: Bool
    let subtitleRight: String
    let savings: String?
    let extra: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                if popular {
                    Text("POPULAR")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundStyle(Color("LexiconText"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color("AmberAccent"))
                        .clipShape(Capsule())
                        .padding(.leading, 12)
                        .offset(y: 8)
                        .zIndex(1)
                }
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color("AmberAccent") : Color("ParchmentBackground").opacity(0.45),
                                    lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                        if isSelected {
                            Circle()
                                .fill(Color("AmberAccent"))
                                .frame(width: 12, height: 12)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(product.displayName)
                                .font(.system(.headline, design: .serif))
                                .foregroundStyle(Color("ParchmentBackground"))
                            if let savings {
                                Text(savings)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color("AmberAccent"))
                            }
                        }
                    }
                    Spacer(minLength: 4)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice)
                            .font(.system(.title3, design: .serif, weight: .bold))
                            .foregroundStyle(Color("AmberAccent"))
                        if !subtitleRight.isEmpty {
                            Text(subtitleRight)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color("ParchmentBackground").opacity(0.6))
                        } else if let extra {
                            Text(extra)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color("ParchmentBackground").opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color("DarkCardRaised") : Color("DarkCard"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color("AmberAccent") : Color("ParchmentBackground").opacity(0.1),
                            lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
