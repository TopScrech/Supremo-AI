import SwiftUI

struct ChatDetailView: View {
    @Environment(ChatAppModel.self) private var appModel
    
    @State private var prompt = ""
    @State private var useRAG = false
    @State private var showSettings = false
    @State private var showModelInstall = false
    let chat: ChatConfiguration
    
    var body: some View {
        VStack {
            if !appModel.isModelReady(for: chat) {
                MissingModelView(
                    chat: chat,
                    installAction: {
                        showModelInstall = true
                    },
                    editAction: {
                        showSettings = true
                    }
                )
            } else if !appModel.isInferenceBackendAvailable {
                MissingInferenceBackendView(chat: chat) {
                    showModelInstall = true
                }
            } else if chat.messages.isEmpty {
                ContentUnavailableView("Start a Conversation", systemImage: "text.bubble", description: Text(chat.modelName))
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading) {
                            ForEach(chat.messages) {
                                MessageBubbleView(message: $0, style: chat.settings.style)
                                    .id($0.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chat.messages.count) { _, _ in
                        if let lastMessage = chat.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            ChatInputBar(prompt: $prompt, useRAG: $useRAG, isGenerating: appModel.isGenerating, sendAction: sendPrompt)
                .padding()
                .disabled(!appModel.canRunChat(chat))
        }
        .navigationTitle(chat.title)
        .toolbar {
            ToolbarItemGroup {
                Button("Install Model", systemImage: "arrow.down.circle") {
                    showModelInstall = true
                }
                Button("Clear", systemImage: "eraser") {
                    appModel.clearMessages(in: chat)
                }
                Button("Edit Chat", systemImage: "slider.horizontal.3") {
                    showSettings = true
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                ChatSettingsEditorView(chat: chat)
            }
        }
        .sheet(isPresented: $showModelInstall) {
            NavigationStack {
                ModelInstallView()
            }
        }
    }
    
    private func sendPrompt() {
        let text = prompt
        prompt = ""
        Task {
            await appModel.sendPrompt(text, useRAG: useRAG)
        }
    }
}
