import SwiftUI

struct ChatSettingsEditor: View {
    @Environment(ChatAppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var draft: ChatConfiguration
    @State private var section = ChatSettingsSection.basic
    
    init(chat: ChatConfiguration) {
        _draft = State(initialValue: chat)
    }
    
    var body: some View {
        VStack {
            Picker("Section", selection: $section) {
                ForEach(ChatSettingsSection.allCases) {
                    Text($0.label)
                        .tag($0)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Form {
                switch section {
                case .basic:
                    BasicChatSettings(chat: $draft)
                    
                case .prediction:
                    PredictionSettingsSection(settings: $draft.settings.prediction)
                    
                case .prompt:
                    PromptSettingsSection(settings: $draft.settings.prompt)
                    
                case .sampling:
                    SamplingSettingsSection(settings: $draft.settings.sampling)
                    
                case .rag:
                    RagSettingsSection(chat: $draft)
                }
            }
        }
        .navigationTitle(draft.title)
        .scrollIndicators(.never)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", systemImage: "checkmark") {
                    appModel.updateChat(draft)
                    dismiss()
                }
            }
        }
    }
}
