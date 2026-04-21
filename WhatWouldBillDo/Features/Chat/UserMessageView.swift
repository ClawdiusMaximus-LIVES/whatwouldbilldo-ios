import SwiftUI

struct UserMessageView: View {
    let message: DisplayMessage

    var body: some View {
        HStack {
            Spacer(minLength: 56)
            Text(message.content)
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(Color("LexiconText"))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("AmberAccent").opacity(0.15))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color("AmberAccent").opacity(0.35), lineWidth: 1)
                )
                .accessibilityLabel("You said: \(message.content)")
        }
    }
}

#Preview {
    UserMessageView(message: DisplayMessage(
        role: "user",
        content: "I'm struggling with a craving right now. Work was brutal and I just want to drink to make it stop."
    ))
    .padding()
    .background(Color("ParchmentBackground"))
}
