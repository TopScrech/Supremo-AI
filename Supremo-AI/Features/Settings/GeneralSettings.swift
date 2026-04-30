import ScrechKit

struct GeneralSettings: View {
    @Environment(ChatAppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage(AppStorageKey.disableStatusBar) private var disableStatusBar = false
    @AppStorage(AppStorageKey.debugMode) private var debugMode = false
    @AppStorage(AppStorageKey.typingAnimationEnabled) private var typingAnimationEnabled = true
    
    var body: some View {
        Form {
            Section("Status Bar") {
                Toggle("Disable Status Bar", isOn: $disableStatusBar)
            }
            
            Section("Chat") {
                Toggle("Typing Animation", isOn: $typingAnimationEnabled)
                    .onChange(of: typingAnimationEnabled) { _, newValue in
                        appModel.setTypingAnimationEnabled(newValue)
                    }
            }
            
            Section("Debug") {
                Toggle("Debug Mode", isOn: $debugMode)
                
                Group {
                    if appModel.isTestingAllModels {
                        Button("Stop all testing", systemImage: "stop.fill", role: .destructive) {
                            appModel.stopTestingAllModels()
                        }
                    } else {
                        Button("Test all downloaded models") {
                            dismiss()
                            appModel.testAllModels()
                        }
                        .disabled(appModel.modelFiles.allSatisfy { !$0.isAvailableLocally || $0.isMultimodalProjector })
                    }
                }
                .foregroundStyle(.foreground)
                
                if let status = appModel.testAllModelsStatus {
                    Text(status)
                        .caption()
                        .secondary()
                }
            }
        }
    }
}
