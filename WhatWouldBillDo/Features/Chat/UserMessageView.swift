import SwiftUI

struct UserMessageView: View {
    let message: DisplayMessage

    var body: some View {
        HStack {
            Spacer(minLength: 40)
            Text(message.content)
                .font(.system(size: 16))
                .foregroundStyle(Color("LexiconText"))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16,
                                                              bottomLeading: 16,
                                                              bottomTrailing: 16,
                                                              topTrailing: 4))
                        .fill(Color("AmberAccent").opacity(0.12))
                )
                .overlay(
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16,
                                                              bottomLeading: 16,
                                                              bottomTrailing: 16,
                                                              topTrailing: 4))
                        .stroke(Color("AmberAccent").opacity(0.2), lineWidth: 1)
                )
                .accessibilityLabel("You said: \(message.content)")
        }
    }
}

#Preview {
    UserMessageView(message: DisplayMessage(role: "user", content: "I'm struggling with resentment."))
        .padding()
        .background(Color("ParchmentBackground"))
}
