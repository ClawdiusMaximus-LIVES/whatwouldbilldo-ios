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
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text("🕯️").font(.system(size: 18))
                        Text("Ask Bill")
                            .font(.system(.title3, design: .serif))
                            .foregroundStyle(Color("LexiconText"))
                    }
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ChatViewModel(modelContext: modelContext, appState: appState)
            }
        }
    }
}

private struct ChatContent: View {
    @Bindable var viewModel: ChatViewModel
    @Environment(AppState.self) private var appState

    private let suggestions = [
        "I'm struggling with a resentment.",
        "I'm working on my Step 4.",
        "I had a craving come up today.",
        "I relapsed. Now what?"
    ]

    var body: some View {
        VStack(spacing: 0) {
            if !appState.isSubscribed {
                remainingBanner
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.messages.isEmpty && !viewModel.isLoading {
                            emptyState
                                .padding(.top, 40)
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
                            BillTypingIndicatorView()
                                .id("typing")
                        }

                        if let err = viewModel.errorMessage {
                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(Color("CrisisRed"))
                                .padding(.top, 8)
                        }
                    }
                    .padding(20)
                }
                .onChange(of: viewModel.messages) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.isLoading) { _, loading in
                    if loading { scrollToBottom(proxy: proxy, anchor: "typing") }
                }
            }

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
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallSheet()
        }
        .fullScreenCover(item: Binding(
            get: { viewModel.crisisResponse },
            set: { newValue in if newValue == nil { viewModel.dismissCrisis() } }
        )) { payload in
            CrisisView(payload: payload) {
                viewModel.dismissCrisis()
            }
        }
    }

    private var remainingBanner: some View {
        let remaining = max(0, 3 - appState.freeConvosUsed)
        return HStack {
            Spacer()
            Text("\(remaining) conversation\(remaining == 1 ? "" : "s") remaining")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color("AmberAccent"))
            Spacer()
        }
        .padding(.vertical, 6)
        .background(Color("AmberAccent").opacity(0.08))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🕯️").font(.system(size: 56))
            VStack(spacing: 4) {
                Text("Ask Bill anything.")
                    .font(.system(.title2, design: .serif))
                    .italic()
                    .foregroundStyle(Color("LexiconText"))
                Text("He's been through it all.")
                    .font(.system(.body, design: .serif))
                    .italic()
                    .foregroundStyle(Color("SaddleBrown"))
            }
            VStack(spacing: 10) {
                ForEach(suggestions, id: \.self) { prompt in
                    Button {
                        viewModel.inputText = prompt
                    } label: {
                        Text(prompt)
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(Color("LexiconText"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color("OldPaper"))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color("AgedGold"), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 12)
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
