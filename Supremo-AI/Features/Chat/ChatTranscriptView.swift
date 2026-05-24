import SwiftUI

struct ChatTranscriptView: View {
    @Environment(ChatAppModel.self) private var appModel
    
    private let chat: ChatConfiguration
    
    init(_ chat: ChatConfiguration) {
        self.chat = chat
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
            }
        }
    }
}
