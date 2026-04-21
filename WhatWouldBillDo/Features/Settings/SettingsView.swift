import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var purchases = PurchaseManager.shared

    @State private var showSobrietyEditor: Bool = false
    @State private var sobrietyDraft: Date = Date()
    @State private var showPaywall: Bool = false
    @State private var showSourceTexts: Bool = false
    @State private var showDisclaimer: Bool = false
    @State private var showRestoreError: String?

    @State private var apiStatus: String = "Checking…"
    @State private var apiPassagesCount: Int?

    var body: some View {
        NavigationStack {
            List {
                journeySection
                subscriptionSection
                aboutSection
                legalSection
                developerSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color("ParchmentBackground"))
            .navigationTitle("Settings")
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

    private var journeySection: some View {
        Section {
            Button {
                sobrietyDraft = appState.sobrietyDate ?? Date()
                showSobrietyEditor = true
            } label: {
                HStack {
                    Text("Sobriety Date")
                        .foregroundStyle(Color("LexiconText"))
                    Spacer()
                    if let date = appState.sobrietyDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .foregroundStyle(Color("SaddleBrown"))
                    } else {
                        Text("Not set")
                            .foregroundStyle(Color("SaddleBrown"))
                    }
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            if let days = appState.daysSober {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Days Sober")
                        .font(.subheadline)
                        .foregroundStyle(Color("SaddleBrown"))
                    HStack {
                        Text("\(days)")
                            .font(.system(size: 44, weight: .bold, design: .serif))
                            .foregroundStyle(Color("AmberAccent"))
                            .contentTransition(.numericText())
                        Spacer()
                    }
                }
                .padding(.vertical, 4)
            }

            if let days = appState.daysSober, let milestone = Milestones.current(for: days) {
                MilestoneCardView(milestone: milestone)
                    .listRowBackground(Color("AmberAccent").opacity(0.08))
            }
        } header: {
            sectionHeader("My Journey")
        }
    }

    private var sobrietyEditorSheet: some View {
        NavigationStack {
            ZStack {
                Color("ParchmentBackground").ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Your sobriety date")
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(Color("LexiconText"))
                    DatePicker("Sobriety Date",
                               selection: $sobrietyDraft,
                               in: ...Date(),
                               displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color("OldPaper")))
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
                                .padding(.horizontal, 28)
                                .padding(.vertical, 12)
                                .background(Color("AmberAccent"))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSobrietyEditor = false }
                }
            }
        }
    }

    // MARK: Subscription

    private var subscriptionSection: some View {
        Section {
            if appState.isSubscribed || purchases.isSubscribed {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.teal)
                    Text("Active")
                        .foregroundStyle(Color("LexiconText"))
                }
                if let id = purchases.activeProductID {
                    LabeledContent("Plan", value: planName(for: id))
                }
                Link(destination: URL(string: "itms-apps://apps.apple.com/account/subscriptions")!) {
                    Text("Manage Subscription")
                        .foregroundStyle(Color("AmberAccent"))
                }
            } else {
                let remaining = max(0, 3 - appState.freeConvosUsed)
                Text("\(remaining) free conversation\(remaining == 1 ? "" : "s") remaining")
                    .foregroundStyle(Color("SaddleBrown"))
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Text("Unlock Bill")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "lock.open.fill")
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("AmberAccent"))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }

            Button("Restore Purchases") {
                Task {
                    do {
                        try await purchases.restorePurchases()
                        if purchases.isSubscribed { appState.isSubscribed = true }
                    } catch {
                        showRestoreError = error.localizedDescription
                    }
                }
            }
            if let err = showRestoreError {
                Text(err)
                    .font(.footnote)
                    .foregroundStyle(Color("CrisisRed"))
            }
        } header: {
            sectionHeader("Subscription")
        }
    }

    private func planName(for id: String) -> String {
        if id.contains("weekly") { return "Weekly" }
        if id.contains("monthly") { return "Monthly" }
        if id.contains("yearly") { return "Yearly" }
        return id
    }

    // MARK: About

    private var aboutSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("About Bill W.")
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Color("LexiconText"))
                Text("William Griffith Wilson (1895–1971). Co-founder of Alcoholics Anonymous. His writings have helped millions find sobriety.")
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(Color("SaddleBrown"))
            }
            .padding(.vertical, 4)

            Button {
                showSourceTexts = true
            } label: {
                Text("View Source Texts")
                    .foregroundStyle(Color("AmberAccent"))
            }
        } header: {
            sectionHeader("About Bill W.")
        }
    }

    // MARK: Legal

    private var legalSection: some View {
        Section {
            DisclosureGroup(isExpanded: $showDisclaimer) {
                Text("This app is not affiliated with Alcoholics Anonymous World Services, Inc. It is independent and uses only Bill W.'s public domain writings (pre-1952).")
                    .font(.footnote)
                    .foregroundStyle(Color("SaddleBrown"))
            } label: {
                Text("Not affiliated with AAWS")
                    .foregroundStyle(Color("LexiconText"))
            }

            Link("Privacy Policy", destination: URL(string: "https://whatwouldbilldo.com/privacy")!)
            Link("Terms of Service", destination: URL(string: "https://whatwouldbilldo.com/terms")!)
            Link("Send Feedback", destination: URL(string: "mailto:hello@whatwouldbilldo.com")!)
        } header: {
            sectionHeader("Legal")
        }
    }

    // MARK: Developer

    private var developerSection: some View {
        Section {
            LabeledContent("Version",
                           value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
            LabeledContent("Build",
                           value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—")
            HStack {
                Text("API Status")
                    .foregroundStyle(Color("LexiconText"))
                Spacer()
                Text(apiStatus)
                    .font(.footnote)
                    .foregroundStyle(apiStatus.starts(with: "✓") ? .teal : Color("CrisisRed"))
            }
        } header: {
            sectionHeader("Developer")
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .tracking(1.2)
            .foregroundStyle(Color("AmberAccent"))
    }

    private func checkAPI() async {
        do {
            let ok = try await APIClient.shared.checkHealth()
            apiStatus = ok ? "✓ Connected" : "⚠ Degraded"
        } catch {
            apiStatus = "⚠ Offline"
        }
    }
}

// MARK: Milestones

struct Milestone {
    let days: Int
    let label: String
    let message: String
}

enum Milestones {
    static let all: [Milestone] = [
        Milestone(days: 1,    label: "Your first day",
                  message: "One day. That was my first, too. Keep coming back."),
        Milestone(days: 7,    label: "One week",
                  message: "A week without a drink. You've done something most cannot."),
        Milestone(days: 30,   label: "Thirty days",
                  message: "Thirty days. You've broken something that was breaking you."),
        Milestone(days: 60,   label: "Two months",
                  message: "Two months. The habit is loosening its grip."),
        Milestone(days: 90,   label: "Ninety days",
                  message: "Ninety days. You are becoming who you were meant to be."),
        Milestone(days: 180,  label: "Six months",
                  message: "Six months. You are not the same person who started."),
        Milestone(days: 365,  label: "One year",
                  message: "One year. You have given yourself a life."),
        Milestone(days: 730,  label: "Two years",
                  message: "Two years. You are free."),
        Milestone(days: 1825, label: "Five years",
                  message: "Five years. Your story saves others now.")
    ]

    static func current(for days: Int) -> Milestone? {
        all.first(where: { $0.days == days })
    }

    static func next(after days: Int) -> Milestone? {
        all.first(where: { $0.days > days })
    }
}

private struct MilestoneCardView: View {
    let milestone: Milestone

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(milestone.label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.2)
                .foregroundStyle(Color("AmberAccent"))
            Text(milestone.message)
                .font(.system(.body, design: .serif))
                .italic()
                .foregroundStyle(Color("LexiconText"))
        }
        .padding(.vertical, 4)
    }
}

// MARK: Source Texts

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
