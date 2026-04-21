import SwiftUI

struct ChatView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color("ParchmentBackground").ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("🕯️")
                        .font(.system(size: 56))
                    Text("Ask Bill anything.")
                        .font(.system(size: 22, design: .serif))
                        .italic()
                        .foregroundStyle(Color("SaddleBrown"))
                    Text("Chat UI arrives in S5.")
                        .font(.caption)
                        .foregroundStyle(Color("SaddleBrown").opacity(0.7))
                }
            }
            .navigationTitle("Ask Bill")
        }
    }
}

#Preview {
    ChatView()
}
