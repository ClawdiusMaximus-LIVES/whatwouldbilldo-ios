import SwiftUI

struct DailyReflectionView: View {
    @Environment(AppState.self) private var appState
    @State private var reflection: DailyReflectionResponse?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color("ParchmentBackground").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        if let reflection {
                            passageCard(reflection: reflection)
                            reflectionSection(reflection: reflection)
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
                                    .font(.footnote)
                                    .foregroundStyle(Color("AmberAccent"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        }

                        if let _ = appState.sobrietyDate {
                            sobrietyCard
                                .padding(.top, 24)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Reflection")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if reflection == nil { await load() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today's Reflection")
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundStyle(Color("LexiconText"))
            Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color("AmberAccent"))
        }
    }

    private func passageCard(reflection: DailyReflectionResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(reflection.passage)
                .font(.system(size: 16, design: .serif))
                .italic()
                .foregroundStyle(Color("LexiconText"))
                .lineSpacing(4)

            if shouldShowSource(reflection.source) {
                Rectangle()
                    .fill(Color("AgedGold"))
                    .frame(height: 1)
                Text("— \(reflection.source)")
                    .font(.system(size: 11, design: .monospaced))
                    .italic()
                    .foregroundStyle(Color("SaddleBrown"))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 4,
                                                      bottomLeading: 16,
                                                      bottomTrailing: 16,
                                                      topTrailing: 16))
                .fill(Color("OldPaper"))
        )
        .overlay(
            UnevenRoundedRectangle(cornerRadii: .init(topLeading: 4,
                                                      bottomLeading: 16,
                                                      bottomTrailing: 16,
                                                      topTrailing: 16))
                .stroke(Color("AgedGold"), lineWidth: 1)
        )
        .shadow(color: .brown.opacity(0.12), radius: 4, y: 2)
    }

    private func reflectionSection(reflection: DailyReflectionResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("BILL'S REFLECTION")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(Color("AmberAccent"))
            Text(reflection.reflection)
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(Color("LexiconText"))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func askButton(reflection: DailyReflectionResponse) -> some View {
        Button {
            appState.pendingChatPrompt = "I was just reading: \"\(reflection.passage)\". What should I take from this?"
            appState.selectedTab = 0
        } label: {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                Text("Ask Bill about this")
            }
            .font(.system(.headline, design: .serif))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color("AmberAccent"))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var sobrietyCard: some View {
        VStack(spacing: 6) {
            Text("\(appState.daysSober ?? 0)")
                .font(.system(size: 52, weight: .bold, design: .serif))
                .foregroundStyle(Color("AmberAccent"))
                .contentTransition(.numericText())
            Text(milestoneLabel(for: appState.daysSober ?? 0))
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color("SaddleBrown"))
            Capsule()
                .fill(Color("AmberAccent").opacity(0.25))
                .frame(width: 48, height: 3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color("OldPaper")))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color("AgedGold"), lineWidth: 1))
    }

    private func milestoneLabel(for days: Int) -> String {
        switch days {
        case 0: return "YOUR FIRST DAY"
        case 1: return "1 DAY"
        case 2..<7: return "\(days) DAYS"
        case 7..<30: return "\(days) DAYS"
        case 30..<90: return "\(days / 30) MONTH"
        case 90..<180: return "\(days / 30) MONTHS"
        case 180..<365: return "6 MONTHS"
        case 365..<730: return "1 YEAR"
        default: return "\(days / 365) YEARS"
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
