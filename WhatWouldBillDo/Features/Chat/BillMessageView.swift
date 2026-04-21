import SwiftUI

struct BillMessageView: View {
    let message: DisplayMessage
    /// Number of characters currently revealed. `nil` means show the full message.
    let revealCount: Int?
    var onTap: (() -> Void)? = nil

    private var isRevealing: Bool { revealCount != nil }

    private var displayedContent: String {
        guard let count = revealCount else { return message.content }
        let clamped = max(0, min(count, message.content.count))
        return String(message.content.prefix(clamped))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("🕯️").font(.system(size: 13))
                Text("BILL W.")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(Color("AmberAccent"))
            }
            .padding(.leading, 2)

            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(Color("AmberAccent"))
                    .frame(width: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                Text(displayedContent)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 14)
                    .padding(.trailing, 16)
                    .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("CardWhite"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("AgedGold").opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .brown.opacity(0.08), radius: 6, y: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Bill says: \(message.content)")
        .contentShape(Rectangle())
        .onTapGesture {
            if isRevealing { onTap?() }
        }
    }

}

#Preview {
    BillMessageView(
        message: DisplayMessage(
            role: "bill",
            content: "I hear what you're saying. And I know that feeling — the idea that one drink might take the edge off what's eating at you. I've been there. For men and women like us, that thought is the beginning of a very bad road.",
            citations: [Citation(source: "Alcoholics Anonymous (1939)",
                                 chapter: "Chapter 6: Into Action", title: nil, similarity: 0.9)]
        ),
        revealCount: nil
    )
    .padding()
    .background(Color("ParchmentBackground"))
}
