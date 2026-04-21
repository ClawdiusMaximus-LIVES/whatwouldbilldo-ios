import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var viewModel: ChatViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    ChatContent(viewModel: viewModel)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("ParchmentBackground"))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("🕯️")
                        .font(.system(size: 20))
                        .accessibilityHidden(true)
                }
                ToolbarItem(placement: .principal) {
                    Text("Ask Bill")
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Color("LexiconText"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !appState.isSubscribed {
                        let remaining = max(0, 3 - appState.freeConvosUsed)
                        Text("\(remaining) left")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color("AmberAccent"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .overlay(
                                Capsule().stroke(Color("AmberAccent").opacity(0.6), lineWidth: 1)
                            )
                    }
                }
            }
            .toolbarBackground(Color("ParchmentBackground"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ChatViewModel(modelContext: modelContext, appState: appState)
            }
            consumePendingPromptIfAny()
        }
        .onChange(of: appState.pendingChatPrompt) { _, _ in
            consumePendingPromptIfAny()
        }
    }

    private func consumePendingPromptIfAny() {
        guard let prompt = appState.pendingChatPrompt,
              let vm = viewModel else { return }
        vm.inputText = prompt
        appState.pendingChatPrompt = nil
    }
}

private struct ChatContent: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(AppState.self) private var appState

    private let suggestions = [
        "I'm struggling with a craving right now.",
        "I had a resentment come up today.",
        "I'm working through Step 4 and I'm stuck.",
        "I relapsed. I don't know what to do."
    ]

    var body: some View {
        VStack(spacing: 0) {
            Divider().background(Color("AgedGold").opacity(0.2))

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 18) {
                        if viewModel.messages.isEmpty && !viewModel.isLoading {
                            emptyState.padding(.top, 24)
                        }

                        ForEach(viewModel.messages) { message in
                            Group {
                                if message.role == "bill" {
                                    BillMessageView(
                                        message: message,
                                        enableTypewriter: isLastBillMessage(message)
                                    )
                                } else {
                                    UserMessageView(message: message)
                                }
                            }
                            .id(message.id)
                        }

                        if viewModel.isLoading {
                            BillTypingIndicatorView().id("typing")
                        }

                        if let err = viewModel.errorMessage {
                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(Color("CrisisRed"))
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .onChange(of: viewModel.messages) { _, _ in scrollToBottom(proxy: proxy) }
                .onChange(of: viewModel.isLoading) { _, loading in
                    if loading { scrollToBottom(proxy: proxy, anchor: "typing") }
                }
            }

            Divider().background(Color("AgedGold").opacity(0.2))

            MessageInputView(
                text: $viewModel.inputText,
                isSending: viewModel.isLoading,
                onSend: { text in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    Task { await viewModel.sendMessage(text) }
                }
            )
        }
        .background(Color("ParchmentBackground").ignoresSafeArea())
        .sheet(isPresented: $viewModel.showPaywall) { PaywallSheet() }
        .fullScreenCover(item: Binding(
            get: { viewModel.crisisResponse },
            set: { newValue in if newValue == nil { viewModel.dismissCrisis() } }
        )) { payload in
            CrisisView(payload: payload) { viewModel.dismissCrisis() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            AnimatedCandle(size: 48)

            VStack(spacing: 6) {
                Text("Bill is listening.")
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(Color("LexiconText"))
                Text("Ask him anything. He's been through it all — the darkness, the doubt, the long road back.")
                    .font(.system(.subheadline, design: .serif))
                    .italic()
                    .foregroundStyle(Color("SaddleBrown"))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
            }
            .padding(.top, -6)

            VStack(spacing: 10) {
                ForEach(suggestions, id: \.self) { prompt in
                    Button { viewModel.inputText = prompt } label: {
                        Text("\u{201C} \(prompt) \u{201D}")
                            .font(.system(.subheadline, design: .serif))
                            .italic()
                            .foregroundStyle(Color("LexiconText"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color("CardWhite"))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color("AgedGold").opacity(0.35), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 10)
        }
    }

    private func isLastBillMessage(_ message: DisplayMessage) -> Bool {
        guard message.role == "bill" else { return false }
        return viewModel.messages.last(where: { $0.role == "bill" })?.id == message.id
    }

    private func scrollToBottom(proxy: ScrollViewProxy, anchor: String? = nil) {
        if let anchor {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(anchor, anchor: .bottom)
            }
        } else if let lastID = viewModel.messages.last?.id {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(lastID, anchor: .bottom)
            }
        }
    }
}

extension CrisisPayload: Identifiable {
    var id: String { message }
}

#Preview {
    ChatView()
        .environment(AppState())
        .modelContainer(for: [Conversation.self, Message.self], inMemory: true)
}
