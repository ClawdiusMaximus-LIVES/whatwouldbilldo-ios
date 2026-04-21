import SwiftUI
import StoreKit

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var purchases = PurchaseManager.shared

    @State private var currentIndex: Int = 0
    @State private var selectedNeeds: Set<String> = []
    @State private var sobrietyDate: Date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    @State private var sobrietyDateWasSet: Bool = false

    private let totalScreens = 4

    var body: some View {
        ZStack {
            Color("ParchmentBackground").ignoresSafeArea()

            VStack(spacing: 0) {
                progressDots
                    .padding(.top, 20)

                TabView(selection: $currentIndex) {
                    IntroScreen(onContinue: advance)
                        .tag(0)
                    NeedsScreen(selectedNeeds: $selectedNeeds, onContinue: advance)
                        .tag(1)
                    SobrietyScreen(date: $sobrietyDate,
                                    dateWasSet: $sobrietyDateWasSet,
                                    onContinue: advance)
                        .tag(2)
                    FreeTrialScreen(products: purchases.products, onStart: completeOnboarding)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: currentIndex)
            }
        }
        .task {
            if purchases.products.isEmpty { await purchases.loadProducts() }
        }
    }

    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalScreens, id: \.self) { i in
                Circle()
                    .fill(i == currentIndex ? Color("AmberAccent") : Color("AgedGold").opacity(0.35))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
    }

    private func advance() {
        if currentIndex < totalScreens - 1 {
            currentIndex += 1
        }
    }

    private func completeOnboarding() {
        appState.needsSelection = Array(selectedNeeds)
        if sobrietyDateWasSet {
            appState.sobrietyDate = sobrietyDate
        }
        appState.isOnboardingComplete = true
    }
}

// MARK: - Screen 1 — Bill's Introduction

private struct IntroScreen: View {
    let onContinue: () -> Void

    private let questions = [
        "What if Bill W. was still here?",
        "What would you ask him?",
        "How could he help when the urge hits?",
        "When you're between a rock and a hard place?",
        "It's 2am. There's no one else to call."
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(questions, id: \.self) { q in
                        Text(q)
                            .font(.system(.callout, design: .serif))
                            .italic()
                            .foregroundStyle(Color("SaddleBrown").opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 12)

                Text("🕯️")
                    .font(.system(size: 80))
                    .shadow(color: Color("AmberAccent").opacity(0.5), radius: 16, y: 4)
                    .padding(.vertical, 12)
                    .accessibilityHidden(true)

                Text("My name is Bill W.")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                    .multilineTextAlignment(.center)

                Text("Bill W. passed away in 1971. But using his complete original writings — the 1939 Big Book and every public domain word he left behind — we've done our best to bring his wisdom back. Ask him anything. It stays between you and Bill.")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Color("SaddleBrown"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Button(action: onContinue) {
                    Text("Meet Bill")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("AmberAccent"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
                .padding(.top, 4)

                Text("Not a replacement for your sponsor — just someone to talk to at 2am when they can't be there. Grounded in Bill W.'s public domain writings (1939). Not affiliated with AAWS.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color("SaddleBrown").opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Screen 2 — Needs

private struct NeedsScreen: View {
    @Binding var selectedNeeds: Set<String>
    let onContinue: () -> Void

    private let options: [(key: String, emoji: String, label: String)] = [
        ("late_night", "🌙", "At 3am when I can't sleep"),
        ("craving",    "⚡", "When I'm facing a craving"),
        ("steps",      "📖", "Working through the Steps"),
        ("talk",       "🤝", "When I need to talk to someone")
    ]

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("When do you need me most?")
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                    .multilineTextAlignment(.center)
                Text("Choose all that apply.")
                    .font(.system(.body, design: .serif))
                    .italic()
                    .foregroundStyle(Color("SaddleBrown"))
            }
            .padding(.top, 24)
            .padding(.horizontal, 28)

            VStack(spacing: 12) {
                ForEach(options, id: \.key) { option in
                    NeedCard(emoji: option.emoji,
                             label: option.label,
                             isSelected: selectedNeeds.contains(option.key)) {
                        toggle(option.key)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color("AmberAccent"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)
            .padding(.bottom, 32)
        }
    }

    private func toggle(_ key: String) {
        if selectedNeeds.contains(key) {
            selectedNeeds.remove(key)
        } else {
            selectedNeeds.insert(key)
        }
    }
}

private struct NeedCard: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(emoji).font(.system(size: 28))
                Text(label)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                    .multilineTextAlignment(.leading)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color("AmberAccent"))
                        .font(.title3)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color("AmberAccent").opacity(0.15) : Color("OldPaper"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color("AmberAccent") : Color("AgedGold"),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Screen 3 — Sobriety Date

private struct SobrietyScreen: View {
    @Binding var date: Date
    @Binding var dateWasSet: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 10) {
                Text("How long have you been on your journey?")
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                    .multilineTextAlignment(.center)
                Text("Optional. This helps Bill be more present with you.")
                    .font(.system(.body, design: .serif))
                    .italic()
                    .foregroundStyle(Color("SaddleBrown"))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 28)
            .padding(.horizontal, 24)

            VStack(spacing: 12) {
                DatePicker("Sobriety Date",
                           selection: $date,
                           in: ...Date(),
                           displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("OldPaper"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color("AgedGold"), lineWidth: 1)
                    )

                Button("I'd rather not say") {
                    dateWasSet = false
                    onContinue()
                }
                .font(.footnote)
                .foregroundStyle(Color("SaddleBrown"))
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 10) {
                Button {
                    dateWasSet = true
                    onContinue()
                } label: {
                    Text("Set My Date")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("AmberAccent"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    dateWasSet = false
                    onContinue()
                } label: {
                    Text("Skip for Now")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Color("SaddleBrown"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Screen 4 — Free Trial + Pricing

private struct FreeTrialScreen: View {
    let products: [Product]
    let onStart: () -> Void
    @State private var purchases = PurchaseManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text("Ask Bill anything.")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundStyle(Color("LexiconText"))
                        .multilineTextAlignment(.center)
                    Text("Not a replacement for your sponsor or your group — just someone to talk to at 2am when they can't be there.")
                        .font(.system(.body, design: .serif))
                        .italic()
                        .foregroundStyle(Color("SaddleBrown"))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                FreeBanner()
                    .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                        PricingCard(product: product,
                                    isMostPopular: product.id.contains("monthly"),
                                    savings: product.id.contains("yearly") ? "Save 62%" : nil)
                    }
                    if products.isEmpty {
                        Text("Loading plans…")
                            .font(.footnote)
                            .foregroundStyle(Color("SaddleBrown"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    }
                }
                .padding(.horizontal, 24)

                Button(action: onStart) {
                    Text("Start for Free")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("AmberAccent"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)

                Button("Restore Purchases") {
                    Task {
                        try? await purchases.restorePurchases()
                    }
                }
                .font(.footnote)
                .foregroundStyle(Color("SaddleBrown"))

                Text("Grounded in Bill W.'s original writings. Not affiliated with AAWS. Not a substitute for professional help.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color("SaddleBrown").opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
            }
        }
    }
}

private struct FreeBanner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("3 Free Conversations Included")
                .font(.system(.headline, design: .serif))
                .foregroundStyle(Color("LexiconText"))
            Text("Ask Bill a real question right now, no payment needed. See for yourself before committing.")
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(Color("SaddleBrown"))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("AmberAccent").opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("AmberAccent").opacity(0.4), lineWidth: 1)
        )
    }
}

private struct PricingCard: View {
    let product: Product
    let isMostPopular: Bool
    let savings: String?

    var body: some View {
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
            Text(product.displayPrice)
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Color("LexiconText"))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color("OldPaper")))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isMostPopular ? Color("AmberAccent") : Color("AgedGold"),
                        lineWidth: isMostPopular ? 2 : 1)
        )
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
