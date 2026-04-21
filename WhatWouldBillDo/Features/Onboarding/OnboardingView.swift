import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color("ParchmentBackground").ignoresSafeArea()
            VStack(spacing: 24) {
                Text("🕯️")
                    .font(.system(size: 72))
                Text("My name is Bill W.")
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                Text("Onboarding — S4 builds this out.")
                    .font(.body)
                    .foregroundStyle(Color("SaddleBrown"))
                Button {
                    appState.isOnboardingComplete = true
                } label: {
                    Text("Meet Bill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color("AmberAccent"))
                        .clipShape(Capsule())
                }
            }
            .padding()
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
