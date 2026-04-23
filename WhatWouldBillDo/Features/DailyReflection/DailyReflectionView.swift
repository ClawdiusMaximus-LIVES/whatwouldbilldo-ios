import SwiftUI

struct DailyReflectionView: View {
    @Environment(AppState.self) private var appState
    @State private var reflection: DailyReflectionResponse?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showPaywall: Bool = false
    @State private var pendingReflection: DailyReflectionResponse? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color("ParchmentBackground").ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerBlock
                        if appState.sobrietyDate != nil {
                            daysSoberCard
                        }
                        if let reflection {
                            passageCard(reflection: reflection)
                            reflectionCard(reflection: reflection)
                            askButton(reflection: reflection)
                        } else if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else if let errorMessage {
                            VStack(spacing: 8) {
                                Text("Couldn't load today's reflection.")
                                    .font(.system(.subheadline, design: .serif))
                                    .foregroundStyle(Color("SaddleBrown"))
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(Color("CrisisRed"))
                                Button("Retry") { Task { await load() } }
                                    .foregroundStyle(Color("AmberAccent"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        }
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Daily Reflection")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Color("LexiconText"))
                }
            }
            .toolbarBackground(Color("ParchmentBackground"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task { if reflection == nil { await load() } }
        .sheet(isPresented: $showPaywall) { PaywallSheet() }
        .onChange(of: appState.isSubscribed) { _, isSubscribed in
            guard isSubscribed, let reflection = pendingReflection else { return }
            pendingReflection = nil
            routeToChat(reflection: reflection)
        }
    }

    private func routeToChat(reflection: DailyReflectionResponse) {
        appState.pendingChatPrompt = "I was just reading: \"\(reflection.passage)\". What should I take from this?"
        appState.selectedTab = 0
    }

    private var headerBlock: some View {
        HStack {
            Spacer()
            Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day().year()).uppercased())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(Color("AmberAccent"))
            Spacer()
        }
        .padding(.top, 4)
    }

    private var daysSoberCard: some View {
        let days = appState.daysSober ?? 0
        return HStack(alignment: .top, spacing: 18) {
            Text("\(days.formatted())")
                .font(.system(size: 44, weight: .bold, design: .serif))
                .foregroundStyle(Color("AmberAccent"))
                .contentTransition(.numericText())
            VStack(alignment: .leading, spacing: 2) {
                Text("DAYS SOBER")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(Color("AmberAccent"))
                Text(milestoneLabel(for: days))
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                if let date = appState.sobrietyDate {
                    Text("\(date.formatted(date: .long, time: .omitted)) — your day one")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color("SaddleBrown"))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color("AmberAccent").opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color("AmberAccent").opacity(0.3), lineWidth: 1)
        )
    }

    private func passageCard(reflection: DailyReflectionResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("🕯️").font(.system(size: 12))
                Text("TODAY'S PASSAGE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.4)
                    .foregroundStyle(Color("AmberAccent"))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color("AmberAccent").opacity(0.12))
            .clipShape(Capsule())

            Text(reflection.passage)
                .font(.system(size: 17, design: .serif))
                .italic()
                .foregroundStyle(Color("LexiconText"))
                .lineSpacing(5)

            if shouldShowSource(reflection.source) {
                Rectangle().fill(Color("AgedGold").opacity(0.4)).frame(height: 1)
                Text("— \(reflection.source)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color("SaddleBrown"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color("CardWhite")))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color("AgedGold").opacity(0.35), lineWidth: 1))
        .shadow(color: .brown.opacity(0.08), radius: 6, y: 2)
    }

    private func reflectionCard(reflection: DailyReflectionResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BILL'S MORNING REFLECTION")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Color("AmberAccent"))
                .padding(.horizontal, 4)

            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(Color("AmberAccent"))
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                VStack(alignment: .leading, spacing: 8) {
                    Text("BILL W.")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.5)
                        .foregroundStyle(Color("AmberAccent"))
                    Text(reflection.reflection)
                        .font(.system(size: 15, design: .serif))
                        .foregroundStyle(Color("LexiconText"))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 14)
                .padding(.trailing, 16)
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardWhite")))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("AgedGold").opacity(0.3), lineWidth: 1))
        }
    }

    private func askButton(reflection: DailyReflectionResponse) -> some View {
        Button {
            if appState.canSendMessage() {
                routeToChat(reflection: reflection)
            } else {
                pendingReflection = reflection
                showPaywall = true
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                Text("Ask Bill about this passage")
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .font(.system(.headline, design: .serif))
            .foregroundStyle(Color("AmberAccent"))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color("AmberAccent").opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color("AmberAccent").opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func milestoneLabel(for days: Int) -> String {
        switch days {
        case 0: return "Your first day 🕯️"
        case 1: return "One day 🕯️"
        case 2..<7: return "\(days) days 🕯️"
        case 7..<30: return "\(days) days sober 🕯️"
        case 30..<90: return "About \(days / 30) month\(days / 30 == 1 ? "" : "s") 🕯️"
        case 90..<180: return "About \(days / 30) months 🕯️"
        case 180..<365: return "Six months 🕯️"
        case 365..<730: return "One year 🕯️"
        case 730..<1095: return "Two years 🕯️"
        case 1095..<1825: return "Approaching \(days / 365) years 🕯️"
        default: return "\(days / 365) years 🕯️"
        }
    }

    private func shouldShowSource(_ source: String) -> Bool {
        let low = source.lowercased()
        return !CitationFilter.forbiddenWorks.contains(where: { low.contains($0) })
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let result = try await APIClient.shared.getDailyReflection()
            reflection = result
            WidgetReflectionBridge.write(result)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}

#Preview {
    DailyReflectionView()
        .environment(AppState())
}
