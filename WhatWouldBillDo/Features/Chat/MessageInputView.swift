import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    let isSending: Bool
    let onSend: (String) -> Void

    private let characterLimit = 500

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(Color("LexiconText"))
                        .scrollContentBackground(.hidden)
                        .background(Color("ParchmentBackground"))
                        .frame(minHeight: 42, maxHeight: 140)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)

                    if text.isEmpty {
                        Text("Ask Bill anything…")
                            .font(.system(.body, design: .serif))
                            .italic()
                            .foregroundStyle(Color("SaddleBrown").opacity(0.6))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color("AgedGold"), lineWidth: 1)
                )

                Button {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty, !isSending else { return }
                    onSend(trimmed)
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(isCtaActive ? Color("AmberAccent") : Color("AmberAccent").opacity(0.35))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!isCtaActive)
                .accessibilityLabel("Send message to Bill")
            }

            if text.count > characterLimit - 100 {
                HStack {
                    Spacer()
                    Text("\(text.count)/\(characterLimit)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(text.count >= characterLimit
                                         ? Color("CrisisRed")
                                         : Color("SaddleBrown"))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color("ParchmentBackground"))
        .onChange(of: text) { _, newValue in
            if newValue.count > characterLimit {
                text = String(newValue.prefix(characterLimit))
            }
        }
    }

    private var isCtaActive: Bool {
        !isSending && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
