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
                            Label("Ask Bill", systemImage: "bubble.left.and.bubble.right")
                        }

                    DailyReflectionView()
                        .tag(1)
                        .tabItem {
                            Label("Reflection", systemImage: "book")
                        }

                    SettingsView()
                        .tag(2)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                }
                .tint(Color("AmberAccent"))
                .task {
                    await setupNotificationsOnce()
                }
                .onChange(of: appState.sobrietyDate) { _, newValue in
                    Task { await NotificationManager.shared.scheduleMilestones(sobrietyDate: newValue) }
                }
            }
        }
        .background(Color("ParchmentBackground").ignoresSafeArea())
    }

    private func setupNotificationsOnce() async {
        let notifications = NotificationManager.shared
        await notifications.requestPermissionIfNeeded()
        guard await notifications.isAuthorized else { return }

        var previewBody: String?
        if let data = UserDefaults.standard.data(forKey: "dailyReflectionCache"),
           let cache = try? JSONDecoder().decode(DailyReflectionCache.self, from: data) {
            previewBody = cache.passage
        }
        await notifications.scheduleDailyReflection(bodyPreview: previewBody)
        await notifications.scheduleMilestones(sobrietyDate: appState.sobrietyDate)
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
