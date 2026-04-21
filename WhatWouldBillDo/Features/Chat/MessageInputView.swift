import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    let isSending: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSend: (String) -> Void

    private let characterLimit = 500

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 10) {
                TextField("Ask Bill anything…", text: $text, axis: .vertical)
                    .focused(isFocused)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color("CardWhite"))
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color("AgedGold").opacity(0.4), lineWidth: 1)
                    )

                Button {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty, !isSending else { return }
                    onSend(trimmed)
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
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
                        .foregroundStyle(text.count >= characterLimit ? Color("CrisisRed") : Color("SaddleBrown"))
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
