import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var bindable = appState
        return Group {
            if !appState.isOnboardingComplete {
                OnboardingView()
            } else {
                TabView(selection: $bindable.selectedTab) {
                    ChatView()
                        .tag(0)
                        .tabItem {
                            Label("Ask Bill", systemImage: "bubble.left.and.bubble.right.fill")
                        }

                    DailyReflectionView()
                        .tag(1)
                        .tabItem {
                            Label("Reflection", systemImage: "book.fill")
                        }

                    SettingsView()
                        .tag(2)
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
