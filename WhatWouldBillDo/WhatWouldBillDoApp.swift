import SwiftUI
import SwiftData

// App Store Review Notes:
// This app is an AI chatbot grounded in Bill W.'s public domain writings (1939 Big Book).
// It includes a crisis detection system that immediately redirects to 988 and SAMHSA.
// Not affiliated with AAWS. First 3 conversations are free — no test account needed.

@main
struct WhatWouldBillDoApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    // wwbd://reflection from the home-screen widget → jump to Reflection tab.
                    if url.host == "reflection" {
                        appState.selectedTab = 1
                    }
                }
        }
        .modelContainer(for: [Conversation.self, Message.self])
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                appState.checkAndResetMonthlyCount()
            }
        }
    }
}
