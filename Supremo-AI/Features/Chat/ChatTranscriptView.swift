import SwiftUI

struct ChatTranscriptView: View {
    @Environment(ChatAppModel.self) private var appModel
    
    private let chat: ChatConfiguration
    private let isComposerFocused: Bool
    
    init(_ chat: ChatConfiguration, isComposerFocused: Bool) {
        self.chat = chat
        self.isComposerFocused = isComposerFocused
    }
    
    var body: some View {
        if chat.messages.isEmpty {
            ContentUnavailableView("Start a Conversation", systemImage: "text.bubble", description: Text(chat.modelName))
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ForEach(chat.messages) {
                            MessageBubble(message: $0, style: chat.settings.style, showTokenCount: !appModel.isGenerating)
                                .id($0.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: chat.messages.count) {
                    if let lastMessage = chat.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
                .onChange(of: chat.messages.last?.text) {
                    if let lastMessage = chat.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
                .onChange(of: isComposerFocused) {
                    scrollToBottomAfterLayout(proxy)
                }
            }
        }
    }
    
    private func scrollToBottomAfterLayout(_ proxy: ScrollViewProxy) {
        guard isComposerFocused, let lastMessage = chat.messages.last else { return }
        
        Task {
            await Task.yield()
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
            
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}
