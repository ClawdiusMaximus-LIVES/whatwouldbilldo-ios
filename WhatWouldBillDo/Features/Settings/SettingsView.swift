import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List {
                Section("Journey") {
                    if let date = appState.sobrietyDate {
                        LabeledContent("Sobriety Date", value: date.formatted(date: .abbreviated, time: .omitted))
                    } else {
                        Text("Sobriety date not set")
                            .foregroundStyle(Color("SaddleBrown"))
                    }
                }
                Section("About") {
                    Text("Settings tab is filled out in S7.")
                        .font(.caption)
                        .foregroundStyle(Color("SaddleBrown"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("ParchmentBackground"))
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
