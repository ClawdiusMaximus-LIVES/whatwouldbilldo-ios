import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if !appState.isOnboardingComplete {
                OnboardingView()
            } else {
                TabView {
                    ChatView()
                        .tabItem {
                            Label("Ask Bill", systemImage: "bubble.left.and.bubble.right.fill")
                        }

                    DailyReflectionView()
                        .tabItem {
                            Label("Reflection", systemImage: "book.fill")
                        }

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
                .tint(Color("AmberAccent"))
            }
        }
        .background(Color("ParchmentBackground").ignoresSafeArea())
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
