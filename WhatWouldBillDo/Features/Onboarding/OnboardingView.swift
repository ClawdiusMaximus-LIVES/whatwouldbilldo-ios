import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    @State private var currentIndex: Int = 0
    @State private var selectedNeeds: Set<String> = []
    @State private var sobrietyDate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var sobrietyDateWasSet: Bool = false

    private let totalScreens = 6

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
                    NameScreen(onContinue: advance)
                        .tag(1)
                    NeedsScreen(selectedNeeds: $selectedNeeds, onContinue: advance)
                        .tag(2)
                    SobrietyScreen(date: $sobrietyDate,
                                   dateWasSet: $sobrietyDateWasSet,
                                   onContinue: advance)
                        .tag(3)
                    FreeFeaturesScreen(onContinue: advance)
                        .tag(4)
                    InvitationScreen(userName: appState.userName, onStart: completeOnboarding)
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentIndex)
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
        if screenHeight < 700 { return 58 }
        if screenHeight < 820 { return 70 }
        return 84
    }
}

// MARK: Screen 2 — Name

private struct NameScreen: View {
    @Environment(AppState.self) private var appState
    let onContinue: () -> Void

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        @Bindable var bindable = appState
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Who am I\nspeaking with?")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(Color("LexiconText"))
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Bill always preferred to know a person's name.")
                            .font(.system(size: 17, design: .serif))
                            .italic()
                            .foregroundStyle(Color("SaddleBrown"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    TextField("Your first name", text: $bindable.userName)
                        .focused($isFieldFocused)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .submitLabel(.done)
                        .onSubmit { isFieldFocused = false }
                        .font(.system(size: 20, design: .serif))
                        .foregroundStyle(Color("LexiconText"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("CardWhite"))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("AgedGold"), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    Spacer(minLength: 8)
                }
            }

            VStack(spacing: 10) {
                Button {
                    appState.userName = appState.userName.trimmingCharacters(in: .whitespacesAndNewlines)
                    isFieldFocused = false
                    onContinue()
                } label: {
                    Text("Nice to meet you")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("AmberAccent"))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(appState.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(appState.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)

                Button {
                    appState.userName = ""
                    isFieldFocused = false
                    onContinue()
                } label: {
                    Text("Continue without sharing")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color("SaddleBrown").opacity(0.7))
                        .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
            .background(Color("ParchmentBackground"))
        }
    }
}

// MARK: Screen 3 — Needs

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
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
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

// MARK: Screen 4 — Sobriety Date

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

// MARK: Screen 5 — Free Features

private struct FreeFeaturesScreen: View {
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Yours, every day.")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(Color("LexiconText"))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Two things you get for free, no subscription. Every single day.")
                            .font(.system(size: 15, design: .serif))
                            .italic()
                            .foregroundStyle(Color("SaddleBrown"))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // Daily reflection preview
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Text("🕯️").font(.system(size: 12))
                            Text("TODAY'S PASSAGE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .tracking(1.4)
                                .foregroundStyle(Color("AmberAccent"))
                        }
                        Text("We are neither cocky nor are we afraid. That is our experience. That is how we react so long as we keep in fit spiritual condition.")
                            .font(.system(size: 14, design: .serif))
                            .italic()
                            .foregroundStyle(Color("LexiconText"))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                        Rectangle().fill(Color("AgedGold").opacity(0.4)).frame(height: 1)
                        Text("BILL'S REFLECTION")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(Color("AmberAccent"))
                        Text("Today isn't won or lost all at once — it's won right now, in the next honest choice.")
                            .font(.system(size: 13, design: .serif))
                            .foregroundStyle(Color("LexiconText"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color("CardWhite")))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color("AgedGold").opacity(0.35), lineWidth: 1))
                    .shadow(color: .brown.opacity(0.08), radius: 6, y: 2)
                    .padding(.horizontal, 16)

                    HStack(alignment: .top, spacing: 14) {
                        Image("widget-parchment-medium")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ON YOUR HOME SCREEN")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .tracking(1.3)
                                .foregroundStyle(Color("AmberAccent"))
                            Text("A parchment widget. Keep Bill's words with you. One tap opens today's passage.")
                                .font(.system(size: 13, design: .serif))
                                .foregroundStyle(Color("LexiconText"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 8)
                }
                .frame(minHeight: proxy.size.height - 80)
            }

            VStack {
                Spacer()
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
                .padding(.bottom, 14)
            }
        }
    }
}

// MARK: Screen 6 — Invitation

private struct InvitationScreen: View {
    let userName: String
    let onStart: () -> Void

    private var trimmedName: String {
        userName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = layoutMetrics(for: proxy.size.height)
            ScrollView {
                VStack(spacing: layout.verticalSpacing) {
                    AnimatedCandle(size: layout.candleSize)
                        .padding(.top, layout.candleTopPadding)

                    inviteBody
                        .font(.system(size: layout.bodyFont, design: .serif))
                        .foregroundStyle(Color("LexiconText"))
                        .lineSpacing(layout.bodyLineSpacing)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 340)
                        .padding(.horizontal, 20)

                    Button(action: onStart) {
                        Text("Sit Down with Bill")
                            .font(.system(size: 19, weight: .bold, design: .serif))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color("AmberAccent"))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)

                    VStack(spacing: 2) {
                        Text("3 conversations free. No card required.")
                        Text("Grounded in Bill W.'s public domain writings (1939).")
                        Text("Not affiliated with AAWS.")
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color("SaddleBrown").opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }
                .frame(minHeight: proxy.size.height)
            }
        }
    }

    private var inviteBody: Text {
        let greeting: Text = trimmedName.isEmpty
            ? Text("")
            : Text("\(trimmedName), Bill has time for you.\n\n").bold()
        return greeting
        + Text("This isn't a chatbot. It's Bill.\n\n")
        + Text("Every word he speaks comes from his own hand — the 1939 Big Book, his letters, his talks. The same man who sat across kitchen tables at 3am with strangers. Who knew what it felt like to want a drink more than anything in the world. And found a way through anyway.\n\n")
        + Text("Ask him about that resentment you can't shake. Tell him where you're stuck on Step 4. Say the thing you haven't said out loud yet.").italic()
        + Text("\n\nHe's heard it all. And he has time for you.")
    }

    private struct LayoutMetrics {
        let candleSize: CGFloat
        let candleTopPadding: CGFloat
        let verticalSpacing: CGFloat
        let bodyFont: CGFloat
        let bodyLineSpacing: CGFloat
    }

    private func layoutMetrics(for screenHeight: CGFloat) -> LayoutMetrics {
        if screenHeight < 700 {
            return LayoutMetrics(candleSize: 56, candleTopPadding: 0,
                                 verticalSpacing: 10, bodyFont: 15, bodyLineSpacing: 3)
        }
        if screenHeight < 820 {
            return LayoutMetrics(candleSize: 70, candleTopPadding: 0,
                                 verticalSpacing: 14, bodyFont: 16, bodyLineSpacing: 4)
        }
        return LayoutMetrics(candleSize: 96, candleTopPadding: 6,
                             verticalSpacing: 18, bodyFont: 17, bodyLineSpacing: 5)
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
