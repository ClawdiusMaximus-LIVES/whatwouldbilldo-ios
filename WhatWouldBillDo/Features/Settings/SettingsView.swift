import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var purchases = PurchaseManager.shared

    @State private var showSobrietyEditor: Bool = false
    @State private var sobrietyDraft: Date = Date()
    @State private var showPaywall: Bool = false
    @State private var showSourceTexts: Bool = false
    @State private var restoreError: String?

    @State private var apiStatus: APIStatus = .checking

    enum APIStatus { case checking, connected, offline }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("ParchmentBackground").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        sectionHeader("MY JOURNEY")
                        journeyGroup

                        sectionHeader("SUBSCRIPTION")
                        subscriptionGroup

                        sectionHeader("ABOUT BILL W.")
                        aboutCard

                        sectionHeader("SYSTEM")
                        systemGroup

                        sectionHeader("LEGAL")
                        legalGroup

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Color("LexiconText"))
                }
            }
            .toolbarBackground(Color("ParchmentBackground"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showSobrietyEditor) { sobrietyEditorSheet }
            .sheet(isPresented: $showPaywall) { PaywallSheet() }
            .sheet(isPresented: $showSourceTexts) { SourceTextsSheet() }
        }
        .task {
            await purchases.updateSubscriptionStatus()
            await checkAPI()
        }
    }

    // MARK: Journey

    private var journeyGroup: some View {
        GroupedCard {
            SettingsRow(icon: "📅", title: "Sobriety Date",
                        trailing: appState.sobrietyDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set",
                        showChevron: true) {
                sobrietyDraft = appState.sobrietyDate ?? Date()
                showSobrietyEditor = true
            }
            Divider().foregroundStyle(Color("AgedGold").opacity(0.25))
            SettingsRow(icon: "🕯️", title: "Days Sober",
                        trailing: (appState.daysSober ?? 0).formatted(),
                        trailingColor: Color("AmberAccent"),
                        trailingBold: true,
                        showChevron: false) { }
            Divider().foregroundStyle(Color("AgedGold").opacity(0.25))
            SettingsRow(icon: "🔔", title: "Daily Reflection",
                        trailing: "7:00 AM",
                        showChevron: true) { }
        }
    }

    // MARK: Subscription

    private var subscriptionGroup: some View {
        GroupedCard {
            let isActive = appState.isSubscribed || purchases.isSubscribed

            HStack {
                Text("✨").font(.system(size: 18))
                Text("Status")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                Spacer()
                if isActive {
                    Text("Active")
                        .font(.system(.footnote, design: .serif, weight: .semibold))
                        .foregroundStyle(.teal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.teal.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text("Free")
                        .font(.system(.footnote, design: .serif, weight: .semibold))
                        .foregroundStyle(Color("SaddleBrown"))
                }
            }
            .padding(16)

            Divider().foregroundStyle(Color("AgedGold").opacity(0.25))

            if isActive {
                SettingsRow(icon: "💳", title: "Plan",
                            trailing: purchases.activeProductID.map { planLabel($0) } ?? "Active",
                            trailingColor: Color("AmberAccent"),
                            showChevron: true) {
                    if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }
                Divider().foregroundStyle(Color("AgedGold").opacity(0.25))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(max(0, 3 - appState.freeConvosUsed)) free conversations remaining")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(Color("SaddleBrown"))
                    Button {
                        showPaywall = true
                    } label: {
                        Text("Unlock Bill")
                            .font(.system(.headline, design: .serif))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color("AmberAccent"))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                Divider().foregroundStyle(Color("AgedGold").opacity(0.25))
            }

            SettingsRow(icon: "↩️", title: "Restore Purchases",
                        trailing: nil,
                        showChevron: true) {
                Task {
                    do {
                        try await purchases.restorePurchases()
                        if purchases.isSubscribed { appState.isSubscribed = true }
                    } catch {
                        restoreError = error.localizedDescription
                    }
                }
            }

            if let err = restoreError {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(Color("CrisisRed"))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
    }

    // MARK: About

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("William Griffith Wilson")
                .font(.system(.title3, design: .serif, weight: .bold))
                .foregroundStyle(Color("LexiconText"))

            Text("1895 — 1971 · CO-FOUNDER, ALCOHOLICS ANONYMOUS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(Color("AmberAccent"))
                .fixedSize(horizontal: false, vertical: true)

            Text("\"Bill's\" writings from 1938–1939 are in the public domain and form the foundation of this app. His words have helped millions find and maintain sobriety.")
                .font(.system(.subheadline, design: .serif))
                .italic()
                .foregroundStyle(Color("SaddleBrown"))
                .fixedSize(horizontal: false, vertical: true)

            Button("View Source Texts") { showSourceTexts = true }
                .font(.footnote)
                .foregroundStyle(Color("AmberAccent"))
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color("CardWhite")))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color("AgedGold").opacity(0.3), lineWidth: 1))
    }

    // MARK: System

    private var systemGroup: some View {
        GroupedCard {
            HStack(spacing: 12) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                Text("API Status")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                Spacer()
                Text(statusLabel)
                    .font(.system(.footnote, design: .serif))
                    .foregroundStyle(statusColor)
            }
            .padding(16)

            Divider().foregroundStyle(Color("AgedGold").opacity(0.25))

            HStack {
                Text("Version")
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                Spacer()
                Text("\(versionString) (build \(buildString))")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color("SaddleBrown"))
            }
            .padding(16)
        }
    }

    // MARK: Legal

    private var legalGroup: some View {
        GroupedCard {
            LinkRow(icon: "🔒", title: "Privacy Policy", url: "https://whatwouldbilldo.com/privacy")
            Divider().foregroundStyle(Color("AgedGold").opacity(0.25))
            LinkRow(icon: "📄", title: "Terms of Service", url: "https://whatwouldbilldo.com/terms")
            Divider().foregroundStyle(Color("AgedGold").opacity(0.25))
            LinkRow(icon: "💌", title: "Send Feedback", url: "mailto:hello@whatwouldbilldo.com")
            Divider().foregroundStyle(Color("AgedGold").opacity(0.25))
            VStack(alignment: .leading, spacing: 6) {
                Text("NOT AFFILIATED")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.2)
                    .foregroundStyle(Color("AmberAccent"))
                Text("This app is not affiliated with Alcoholics Anonymous World Services, Inc. It is independent and uses only Bill W.'s public domain writings (pre-1952).")
                    .font(.system(.footnote, design: .serif))
                    .foregroundStyle(Color("SaddleBrown"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
    }

    // MARK: Sobriety editor sheet

    private var sobrietyEditorSheet: some View {
        NavigationStack {
            ZStack {
                Color("ParchmentBackground").ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Your sobriety date")
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(Color("LexiconText"))
                    DatePicker("", selection: $sobrietyDraft,
                               in: ...Date(),
                               displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color("CardWhite")))
                        .padding(.horizontal, 20)

                    HStack(spacing: 12) {
                        Button("Clear") {
                            appState.sobrietyDate = nil
                            showSobrietyEditor = false
                        }
                        .foregroundStyle(Color("CrisisRed"))

                        Spacer()

                        Button {
                            appState.sobrietyDate = sobrietyDraft
                            showSobrietyEditor = false
                        } label: {
                            Text("Save")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(Color("AmberAccent"))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSobrietyEditor = false }
                }
            }
        }
    }

    // MARK: helpers

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(Color("AmberAccent"))
            Spacer()
        }
        .padding(.leading, 8)
        .padding(.top, 4)
    }

    private var statusColor: Color {
        switch apiStatus {
        case .checking: return Color("SaddleBrown")
        case .connected: return .green
        case .offline: return Color("CrisisRed")
        }
    }

    private var statusLabel: String {
        switch apiStatus {
        case .checking: return "Checking…"
        case .connected: return "● Connected"
        case .offline: return "● Offline"
        }
    }

    private var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var buildString: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    private func planLabel(_ id: String) -> String {
        if id.contains("weekly") { return "Weekly · $4.99" }
        if id.contains("monthly") { return "Monthly · $12.99" }
        if id.contains("yearly") { return "Yearly · $59.99" }
        return id
    }

    private func checkAPI() async {
        apiStatus = .checking
        do {
            let ok = try await APIClient.shared.checkHealth()
            apiStatus = ok ? .connected : .offline
        } catch {
            apiStatus = .offline
        }
    }
}

// MARK: Row primitives

private struct GroupedCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color("CardWhite")))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color("AgedGold").opacity(0.3), lineWidth: 1))
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let trailing: String?
    var trailingColor: Color = Color("SaddleBrown")
    var trailingBold: Bool = false
    let showChevron: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Text(icon).font(.system(size: 20))
                Text(title)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.system(trailingBold ? .body : .subheadline,
                                      design: .serif,
                                      weight: trailingBold ? .bold : .regular))
                        .foregroundStyle(trailingColor)
                }
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
}

private struct LinkRow: View {
    let icon: String
    let title: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 14) {
                Text(icon).font(.system(size: 18))
                Text(title)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
        }
    }
}

// MARK: Source texts (unchanged content)

private struct SourceTextsSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let sources: [(title: String, description: String)] = [
        ("Alcoholics Anonymous (1939)", "The original Big Book — first edition."),
        ("Original Manuscript (1938)", "Pre-publication multilith manuscript."),
        ("AA Grapevine articles (early)", "Bill's early essays in the AA magazine."),
        ("Personal letters", "Correspondence available in the public domain."),
        ("Talk transcripts", "Public-domain speeches and talks.")
    ]
    var body: some View {
        NavigationStack {
            ZStack {
                Color("ParchmentBackground").ignoresSafeArea()
                List {
                    Section {
                        ForEach(sources, id: \.title) { source in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(source.title)
                                    .font(.system(.headline, design: .serif))
                                    .foregroundStyle(Color("LexiconText"))
                                Text(source.description)
                                    .font(.system(.subheadline, design: .serif))
                                    .foregroundStyle(Color("SaddleBrown"))
                            }
                            .padding(.vertical, 2)
                        }
                    } header: {
                        Text("PUBLIC DOMAIN SOURCES")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(1.2)
                            .foregroundStyle(Color("AmberAccent"))
                    } footer: {
                        Text("The Twelve & Twelve (1952) and As Bill Sees It (1967) are NOT used — they are still under copyright.")
                            .font(.footnote)
                            .foregroundStyle(Color("SaddleBrown"))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Source Texts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
