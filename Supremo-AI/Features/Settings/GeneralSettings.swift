import ScrechKit

struct GeneralSettings: View {
    @Environment(ChatAppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("disableStatusBar") private var disableStatusBar = false
    @AppStorage("debugMode") private var debugMode = false
    
    var body: some View {
        Form {
            Section("Status Bar") {
                Toggle("Disable Status Bar", isOn: $disableStatusBar)
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
