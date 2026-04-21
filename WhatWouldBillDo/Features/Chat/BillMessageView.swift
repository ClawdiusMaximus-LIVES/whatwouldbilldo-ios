import SwiftUI

struct BillMessageView: View {
    let message: DisplayMessage
    let enableTypewriter: Bool

    @State private var revealedCount: Int = 0
    @State private var revealTask: Task<Void, Never>? = nil

    private var displayedContent: String {
        guard enableTypewriter else { return message.content }
        let count = min(revealedCount, message.content.count)
        return String(message.content.prefix(count))
    }

    private var visibleCitations: [Citation] {
        CitationFilter.filter(message.citations)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BILL W.")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(Color("SaddleBrown"))

            Text(displayedContent)
                .font(.system(.body, design: .serif))
                .foregroundStyle(Color("LexiconText"))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if !visibleCitations.isEmpty {
                Rectangle()
                    .fill(Color("AgedGold"))
                    .frame(height: 1)
                    .padding(.top, 4)

                ForEach(Array(visibleCitations.enumerated()), id: \.offset) { _, citation in
                    Text(formatCitation(citation))
                        .font(.system(size: 11, design: .monospaced))
                        .italic()
                        .foregroundStyle(Color("SaddleBrown"))
                }
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bill says: \(message.content)")
        .onAppear {
            guard enableTypewriter else { return }
            startReveal()
        }
        .onDisappear { revealTask?.cancel() }
    }

    private func startReveal() {
        revealTask?.cancel()
        revealedCount = 0
        revealTask = Task { @MainActor in
            for i in 0...message.content.count {
                if Task.isCancelled { break }
                revealedCount = i
                try? await Task.sleep(nanoseconds: 20_000_000) // 20ms ≈ 50 chars/sec
            }
        }
    }

    private func formatCitation(_ c: Citation) -> String {
        var parts: [String] = ["— From \(c.source)"]
        if let chapter = c.chapter, !chapter.isEmpty { parts.append(chapter) }
        if let title = c.title, !title.isEmpty, c.chapter == nil { parts.append(title) }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    BillMessageView(
        message: DisplayMessage(
            role: "bill",
            content: "Resentment is the number one offender. It destroys more alcoholics than anything else.",
            citations: [Citation(source: "Alcoholics Anonymous", chapter: "How It Works", title: nil, similarity: 0.9)]
        ),
        enableTypewriter: false
    )
    .padding()
    .background(Color("ParchmentBackground"))
}
