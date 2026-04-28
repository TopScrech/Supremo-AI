import ScrechKit
import ChitChat

struct ChatDetailView: View {
    @Environment(ChatAppModel.self) private var appModel
    
    @Binding var selectedSettingsScreen: SettingsScreen
    @Binding var showAppSettings: Bool
    let chat: ChatConfiguration
    
    @FocusState private var isComposerFocused: Bool
    
    @State private var prompt = ""
    @State private var showSettings = false
    @State private var showModelInstall = false
    
    var body: some View {
        @Bindable var appModel = appModel
        
        VStack {
            if !appModel.isModelReady(for: chat) {
                MissingModelView(
                    chat: chat,
                    installAction: {
                        showModelInstall = true
                    }, editAction: {
                        selectedSettingsScreen = .models
                        showAppSettings = true
                    }
                )
            } else if !appModel.isInferenceBackendAvailable {
                MissingInferenceBackend(chat) {
                    showModelInstall = true
                }
            } else if !appModel.isModelInitialized(for: chat) {
                ModelInitializationView(
                    chat: chat,
                    state: appModel.modelInitializationState(for: chat),
                    message: appModel.modelInitializationMessages[chat.id],
                    initializeAction: initializeModel,
                    ejectAction: ejectModel
                ) {
                    showSettings = true
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
            
            let stopAction = appModel.isGenerating ? appModel.stopGenerating : nil
            
            ChatComposer(prompt: $prompt, isResponding: $appModel.isGenerating, isFocused: $isComposerFocused, sendPrompt: sendPrompt, stopAction: stopAction)
                .animation(.default, value: appModel.isGenerating)
                .disabled(!appModel.canRunChat(chat))
        }
        .navigationTitle(chat.title)
        .toolbar {
            ToolbarItem {
                if !chat.messages.isEmpty {
                    Button("Clear", systemImage: "eraser") {
                        appModel.clearMessages(in: chat)
                    }
                }
            }
            
            ToolbarSpacer()
            
            ToolbarItemGroup {
                if appModel.isModelInitialized(for: chat) {
                    Button("Eject Model", systemImage: "eject", action: ejectModel)
                }
                
                Button("Install Model", systemImage: "arrow.down.circle") {
                    showModelInstall = true
                }
                
                Button("Edit Chat", systemImage: "slider.horizontal.3") {
                    showSettings = true
                }
            }
        }
        .sheet($showSettings) {
            NavigationStack {
                ChatSettingsEditor(chat)
            }
        }
        .sheet($showModelInstall) {
            NavigationStack {
                ModelInstallView()
            }
        }
    }
    
    private func sendPrompt() {
        let text = prompt
        prompt = ""
        
        Task {
            await appModel.sendPrompt(text, useRAG: false)
        }
    }
    
    private func initializeModel() {
        Task {
            await appModel.initializeModel(for: chat)
            
            if appModel.isModelInitialized(for: chat) {
                await Task.yield()
                isComposerFocused = true
            }
        }
    }
    
    private func ejectModel() {
        Task {
            await appModel.ejectModel(for: chat)
        }
    }
}
