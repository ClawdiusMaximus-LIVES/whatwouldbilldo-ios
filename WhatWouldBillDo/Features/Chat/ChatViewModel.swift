import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class ChatViewModel {
    var messages: [DisplayMessage] = []
    var isLoading: Bool = false
    var inputText: String = ""
    var errorMessage: String? = nil

    var showPaywall: Bool = false
    var crisisResponse: CrisisPayload? = nil

    var revealProgress: [UUID: Int] = [:]

    var isAnimatingReveal: Bool { !revealProgress.isEmpty }

    private let modelContext: ModelContext
    private let appState: AppState
    private let api: APIClient
    private var activeConversation: Conversation?
    private var revealTask: Task<Void, Never>? = nil

    init(modelContext: ModelContext, appState: AppState, api: APIClient = .shared) {
        self.modelContext = modelContext
        self.appState = appState
        self.api = api
        loadExistingConversation()
    }

    func sendMessage(_ rawText: String) async {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        guard appState.canSendMessage() else {
            showPaywall = true
            return
        }

        errorMessage = nil
        inputText = ""

        let userMessage = DisplayMessage(role: "user", content: text)
        messages.append(userMessage)
        persist(userMessage)

        isLoading = true

        let history = buildHistory()

        do {
            let response = try await api.askBill(message: text, history: history, userName: appState.userName)

            if response.crisis {
                isLoading = false
                crisisResponse = CrisisPayload(
                    message: response.crisis_message
                        ?? "You matter. Please reach out to someone right now.",
                    resources: (response.crisis_resources ?? []).map { dict in
                        CrisisResourceItem(
                            name: dict["name"] ?? "Support",
                            detail: dict["detail"] ?? dict["description"],
                            phone: dict["phone"] ?? dict["number"],
                            textInstructions: dict["text"] ?? dict["sms"],
                            url: dict["url"]
                        )
                    }
                )
                return
            }

            let filteredCitations = CitationFilter.filter(response.citations ?? [])
            let billText = response.response ?? "I'm here. Let me sit with that a moment."
            let billMessage = DisplayMessage(
                role: "bill",
                content: billText,
                citations: filteredCitations
            )
            messages.append(billMessage)
            persist(billMessage)
            startReveal(for: billMessage)

            if !appState.isSubscribed {
                appState.freeConvosUsed += 1
            }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    func dismissCrisis() {
        crisisResponse = nil
    }

    func skipReveal(for id: UUID) {
        guard revealProgress[id] != nil else { return }
        revealTask?.cancel()
        revealProgress.removeValue(forKey: id)
    }

    private func startReveal(for message: DisplayMessage) {
        revealTask?.cancel()
        let id = message.id
        let total = message.content.count
        guard total > 0 else { return }
        revealProgress[id] = 0

        // Cap total reveal time around ~7s for long letters; keep ~18ms/char feel for short ones.
        let perCharNs: UInt64 = max(
            3_000_000,
            min(18_000_000, UInt64(7_000_000_000 / UInt64(max(1, total))))
        )

        revealTask = Task { @MainActor [weak self] in
            var i = 0
            while i <= total {
                if Task.isCancelled { return }
                self?.revealProgress[id] = i
                try? await Task.sleep(nanoseconds: perCharNs)
                i += 1
            }
            self?.revealProgress.removeValue(forKey: id)
        }
    }

    private func buildHistory() -> [[String: String]] {
        messages
            .suffix(12)
            .map { msg in
                [
                    "role": msg.role == "bill" ? "assistant" : "user",
                    "content": msg.content
                ]
            }
    }

    private func loadExistingConversation() {
        var descriptor = FetchDescriptor<Conversation>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        if let latest = try? modelContext.fetch(descriptor).first {
            activeConversation = latest
            messages = latest.messages
                .sorted { $0.timestamp < $1.timestamp }
                .map { msg in
                    DisplayMessage(
                        id: msg.id,
                        role: msg.role,
                        content: msg.content,
                        citations: decodeCitations(msg.citations),
                        timestamp: msg.timestamp
                    )
                }
        }
    }

    private func persist(_ message: DisplayMessage) {
        let conversation: Conversation
        if let existing = activeConversation {
            conversation = existing
        } else {
            let fresh = Conversation()
            modelContext.insert(fresh)
            activeConversation = fresh
            conversation = fresh
        }
        let stored = Message(
            id: message.id,
            role: message.role,
            content: message.content,
            citations: encodeCitations(message.citations),
            timestamp: message.timestamp
        )
        modelContext.insert(stored)
        conversation.messages.append(stored)
        try? modelContext.save()
    }

    private func encodeCitations(_ citations: [Citation]) -> String {
        guard let data = try? JSONEncoder().encode(citations),
              let str = String(data: data, encoding: .utf8) else { return "[]" }
        return str
    }

    private func decodeCitations(_ raw: String) -> [Citation] {
        guard let data = raw.data(using: .utf8),
              let citations = try? JSONDecoder().decode([Citation].self, from: data)
        else { return [] }
        return citations
    }
}

struct CrisisPayload: Equatable {
    let message: String
    let resources: [CrisisResourceItem]
}

struct CrisisResourceItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let detail: String?
    let phone: String?
    let textInstructions: String?
    let url: String?
}
