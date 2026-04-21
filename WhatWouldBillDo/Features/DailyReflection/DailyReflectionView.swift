import SwiftUI

struct DailyReflectionView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color("ParchmentBackground").ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Today's Reflection")
                        .font(.system(size: 24, design: .serif))
                        .foregroundStyle(Color("LexiconText"))
                    Text("Built out in S6.")
                        .font(.caption)
                        .foregroundStyle(Color("SaddleBrown").opacity(0.7))
                }
            }
            .navigationTitle("Reflection")
        }
    }
}

#Preview {
    DailyReflectionView()
}
