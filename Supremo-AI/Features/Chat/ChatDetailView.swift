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
            if !chat.messages.isEmpty {
                ChatTranscriptView(chat: chat)
            } else if !appModel.isModelReady(for: chat) {
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
            } else {
                ChatTranscriptView(chat: chat)
            }
            
            let stopAction = appModel.isGenerating ? appModel.stopGenerating : nil
            
            if appModel.isTestingAllModels {
                Button("Stop all testing", systemImage: "stop.fill", role: .destructive) {
                    appModel.stopTestingAllModels()
                }
#if !os(visionOS)
                .buttonStyle(.glassProminent)
#endif
            }
            
            if !chat.messages.isEmpty && !appModel.canRunChat(chat) {
                ChatUnavailableActionsView(
                    isModelReady: appModel.isModelReady(for: chat),
                    isInferenceBackendAvailable: appModel.isInferenceBackendAvailable,
                    initializationState: appModel.modelInitializationState(for: chat),
                    selectModelAction: selectModel,
                    installModelAction: {
                        showModelInstall = true
                    },
                    initializeAction: initializeModel
                )
            }
            
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
#if !os(visionOS)
            ToolbarSpacer()
#endif
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
    
    private func selectModel() {
        selectedSettingsScreen = .models
        showAppSettings = true
    }
    
    private func ejectModel() {
        Task {
            await appModel.ejectModel(for: chat)
        }
    }
}
