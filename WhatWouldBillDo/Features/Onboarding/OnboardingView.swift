import SwiftUI
import StoreKit

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var purchases = PurchaseManager.shared

    @State private var currentIndex: Int = 0
    @State private var selectedNeeds: Set<String> = []
    @State private var sobrietyDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var sobrietyDateWasSet: Bool = false
    @State private var selectedProductID: String? = nil

    private let totalScreens = 4

    var body: some View {
        ZStack {
            // Screen 1 is dark; others are parchment. Cross-fade.
            (currentIndex == 0 ? Color("DarkBackground") : Color("ParchmentBackground"))
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: currentIndex)

            VStack(spacing: 0) {
                progressDots
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                TabView(selection: $currentIndex) {
                    IntroScreen(onContinue: advance)
                        .tag(0)
                    NeedsScreen(selectedNeeds: $selectedNeeds, onContinue: advance)
                        .tag(1)
                    SobrietyScreen(date: $sobrietyDate,
                                   dateWasSet: $sobrietyDateWasSet,
                                   onContinue: advance)
                        .tag(2)
                    FreeTrialScreen(products: purchases.products,
                                    selectedProductID: $selectedProductID,
                                    onStart: completeOnboarding)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
        }
        .task {
            if purchases.products.isEmpty { await purchases.loadProducts() }
            if selectedProductID == nil,
               let monthly = purchases.products.first(where: { $0.id.contains("monthly") }) {
                selectedProductID = monthly.id
            }
        }
    }

    private var progressDots: some View {
        HStack(spacing: 10) {
            ForEach(0..<totalScreens, id: \.self) { i in
                let active = i == currentIndex
                Capsule()
                    .fill(active ? Color("AmberAccent") : Color("AgedGold").opacity(currentIndex == 0 ? 0.25 : 0.35))
                    .frame(width: active ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentIndex)
            }
        }
    }

    private func advance() {
        if currentIndex < totalScreens - 1 { currentIndex += 1 }
    }

    private func completeOnboarding() {
        appState.needsSelection = Array(selectedNeeds)
        if sobrietyDateWasSet { appState.sobrietyDate = sobrietyDate }
        appState.isOnboardingComplete = true
    }
}

// MARK: Screen 1 — Intro (dark)

private struct IntroScreen: View {
    let onContinue: () -> Void

    private let questions: [(String, Bool)] = [
        ("\"What if Bill W. was still here?\"", false),
        ("\"What would you ask him?\"", false),
        ("\"How could he help when the urge hits?\"", true),
        ("\"When you're between a rock and a hard place?\"", false),
        ("\"It's 2am. There's no one else to call.\"", true),
    ]

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                // Questions block — compact
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(questions.enumerated()), id: \.offset) { _, item in
                        Text(item.0)
                            .font(.system(size: 15, design: .serif))
                            .italic()
                            .fontWeight(item.1 ? .semibold : .regular)
                            .foregroundStyle(Color("ParchmentBackground").opacity(item.1 ? 0.9 : 0.55))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 8)

                Spacer(minLength: 8)

                AnimatedCandle(size: candleSize(for: proxy.size.height), onDark: true)

                Spacer(minLength: 8)

                // Title + body copy
                VStack(alignment: .leading, spacing: 10) {
                    Text("My name\nis Bill W.")
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundStyle(Color("ParchmentBackground"))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Bill W. passed away in 1971. But using his complete original writings — the 1939 Big Book and every public domain word he left behind — we've done our best to bring his wisdom back. Ask him anything.")
                        .font(.system(size: 14, design: .serif))
                        .foregroundStyle(Color("ParchmentBackground").opacity(0.72))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)

                // CTA
                Button(action: onContinue) {
                    Text("Meet Bill")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("AmberAccent"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.top, 14)

                // Footer disclaimer
                Text("Grounded in Bill W.'s original public domain writings (1939). Not affiliated with Alcoholics Anonymous World Services, Inc.")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color("ParchmentBackground").opacity(0.3))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Candle shrinks on short devices so everything fits without scrolling.
    private func candleSize(for screenHeight: CGFloat) -> CGFloat {
        // iPhone SE / mini ~667pt; Pro Max ~956pt
        if screenHeight < 700 { return 54 }
        if screenHeight < 820 { return 64 }
        return 74
    }
}

// MARK: Screen 2 — Needs

struct NeedOption: Identifiable {
    let id: String
    let emoji: String
    let title: String
    let subtitle: String
}

private struct NeedsScreen: View {
    @Binding var selectedNeeds: Set<String>
    let onContinue: () -> Void

    private let options: [NeedOption] = [
        NeedOption(id: "late_night", emoji: "🌙",
                   title: "At 3am when I can't sleep",
                   subtitle: "When the darkness is loudest and your sponsor isn't picking up"),
        NeedOption(id: "craving", emoji: "🔥",
                   title: "When I'm facing a craving",
                   subtitle: "Need to talk it through before it wins"),
        NeedOption(id: "steps", emoji: "📖",
                   title: "Working through the Steps",
                   subtitle: "Step work, inventories, amends — Bill has been through it all"),
        NeedOption(id: "talk", emoji: "💬",
                   title: "When I need to talk to someone",
                   subtitle: "Resentments, family, the hard days nobody else understands")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("When do you\nneed me most?")
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundStyle(Color("LexiconText"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Select all that apply — no judgment here.")
                            .font(.system(.footnote, design: .serif))
                            .italic()
                            .foregroundStyle(Color("SaddleBrown"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                    VStack(spacing: 10) {
                        ForEach(options) { option in
                            NeedCard(option: option, isSelected: selectedNeeds.contains(option.id)) {
                                toggle(option.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 8)
                }
            }

            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("AmberAccent"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 14)
            .background(Color("ParchmentBackground"))
        }
    }

    private func toggle(_ id: String) {
        if selectedNeeds.contains(id) { selectedNeeds.remove(id) } else { selectedNeeds.insert(id) }
    }
}

private struct NeedCard: View {
    let option: NeedOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                Text(option.emoji).font(.system(size: 24))
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(.system(.subheadline, design: .serif, weight: .semibold))
                        .foregroundStyle(Color("LexiconText"))
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                    Text(option.subtitle)
                        .font(.system(size: 12, design: .serif))
                        .foregroundStyle(Color("SaddleBrown"))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                ZStack {
                    Circle()
                        .stroke(Color("AgedGold"), lineWidth: 1)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color("AmberAccent"))
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color("AmberAccent").opacity(0.10) : Color("CardWhite"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color("AmberAccent") : Color("AgedGold").opacity(0.5),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: Screen 3 — Sobriety Date

private struct SobrietyScreen: View {
    @Binding var date: Date
    @Binding var dateWasSet: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("When did your\njourney begin?")
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundStyle(Color("LexiconText"))
                            .fixedSize(horizontal: false, vertical: true)
                        Text("This is just for you — Bill will only mention it when it's truly relevant.")
                            .font(.system(.footnote, design: .serif))
                            .italic()
                            .foregroundStyle(Color("SaddleBrown"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("YOUR SOBRIETY DATE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(Color("AmberAccent"))

                        Text(date.formatted(.dateTime.month(.wide).day().year()))
                            .font(.system(size: 26, weight: .bold, design: .serif))
                            .foregroundStyle(Color("AmberAccent"))
                            .contentTransition(.numericText())

                        SobrietyDateWheel(date: $date)
                            .frame(height: 140)
                            .padding(.top, 2)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color("CardWhite")))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color("AgedGold").opacity(0.35), lineWidth: 1))
                    .padding(.horizontal, 16)

                    DaysSoberMiniCard(date: date)
                        .padding(.horizontal, 16)

                    Spacer(minLength: 6)
                }
            }

            VStack(spacing: 4) {
                Button {
                    dateWasSet = true
                    onContinue()
                } label: {
                    Text("Set My Date")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("AmberAccent"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    dateWasSet = false
                    onContinue()
                } label: {
                    Text("I'd rather not say")
                        .font(.system(.footnote, design: .serif))
                        .foregroundStyle(Color("SaddleBrown"))
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
            .background(Color("ParchmentBackground"))
        }
    }
}

// MARK: Screen 4 — Free Trial

private struct FreeTrialScreen: View {
    let products: [Product]
    @Binding var selectedProductID: String?
    let onStart: () -> Void
    @State private var purchases = PurchaseManager.shared

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ask Bill anything.")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(Color("LexiconText"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Text("Your first 3 conversations are free. Then a small subscription keeps Bill's light on.")
                            .font(.system(.footnote, design: .serif))
                            .italic()
                            .foregroundStyle(Color("LexiconText").opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 20)

                    FreeConversationsBanner()
                        .padding(.horizontal, 16)

                    VStack(spacing: 10) {
                        ForEach(orderedProducts) { product in
                            PricingCard(
                                product: product,
                                isSelected: selectedProductID == product.id,
                                tag: tag(for: product.id),
                                subtitle: subtitle(for: product.id),
                                trailingBadge: trailingBadge(for: product.id)
                            ) {
                                selectedProductID = product.id
                            }
                        }
                        if products.isEmpty {
                            ProgressView().padding(.vertical, 14)
                        }
                    }
                    .padding(.horizontal, 16)

                    Text("Grounded in Bill W.'s original writings. Not affiliated with AA World Services. Not a substitute for professional help.")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color("SaddleBrown").opacity(0.55))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity)

                    Spacer(minLength: 4)
                }
            }

            VStack(spacing: 4) {
                Button(action: onStart) {
                    Text("Start for Free")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("AmberAccent"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button("Restore Purchases") {
                    Task { try? await purchases.restorePurchases() }
                }
                .font(.system(.footnote, design: .serif))
                .underline()
                .foregroundStyle(Color("SaddleBrown"))
                .padding(.vertical, 2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 10)
            .background(Color("ParchmentBackground"))
        }
    }

    private var orderedProducts: [Product] {
        let order = ["weekly", "monthly", "yearly"]
        return products.sorted { lhs, rhs in
            let li = order.firstIndex(where: { lhs.id.contains($0) }) ?? 99
            let ri = order.firstIndex(where: { rhs.id.contains($0) }) ?? 99
            return li < ri
        }
    }

    private func subtitle(for productID: String) -> String {
        if productID.contains("weekly") { return "Billed every week" }
        if productID.contains("monthly") { return "Billed every month" }
        if productID.contains("yearly") { return "Just $5/month · Save 62%" }
        return ""
    }

    private func tag(for productID: String) -> PricingCardTag? {
        productID.contains("monthly") ? .mostPopular : nil
    }

    private func trailingBadge(for productID: String) -> String? {
        if productID.contains("weekly") { return "/ week" }
        if productID.contains("monthly") { return "/ month" }
        if productID.contains("yearly") { return "Save $95.89" }
        return nil
    }
}

private struct FreeConversationsBanner: View {
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("🕯️").font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text("3 Free Conversations Included")
                    .font(.system(.subheadline, design: .serif, weight: .semibold))
                    .foregroundStyle(Color("AmberAccent"))
                Text("Try Bill right now — no payment needed.")
                    .font(.system(size: 12, design: .serif))
                    .foregroundStyle(Color("LexiconText").opacity(0.8))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("AmberAccent").opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color("AmberAccent").opacity(0.35), lineWidth: 1)
        )
    }
}

enum PricingCardTag {
    case mostPopular
}

struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let tag: PricingCardTag?
    let subtitle: String
    let trailingBadge: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                if tag == .mostPopular {
                    Text("MOST POPULAR")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .tracking(1.1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color("AmberAccent"))
                        .clipShape(Capsule())
                        .padding(.leading, 10)
                        .offset(y: 6)
                        .zIndex(1)
                }

                HStack(alignment: .center, spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color("AmberAccent") : Color("AgedGold"), lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                        if isSelected {
                            Circle()
                                .fill(Color("AmberAccent"))
                                .frame(width: 10, height: 10)
                        }
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(product.displayName)
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(Color("LexiconText"))
                        Text(subtitle)
                            .font(.system(size: 11, design: .serif))
                            .foregroundStyle(Color("SaddleBrown"))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 4)

                    VStack(alignment: .trailing, spacing: 0) {
                        Text(product.displayPrice)
                            .font(.system(.headline, design: .serif, weight: .bold))
                            .foregroundStyle(Color("AmberAccent"))
                        if let trailingBadge {
                            Text(trailingBadge)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color("AmberAccent").opacity(0.85))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color("AmberAccent").opacity(0.08) : Color("CardWhite"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color("AmberAccent") : Color("AgedGold").opacity(0.4),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
