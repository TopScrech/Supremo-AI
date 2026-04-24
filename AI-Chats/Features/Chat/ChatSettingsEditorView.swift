import SwiftUI

struct ChatSettingsEditorView: View {
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
                    Text($0.label).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Form {
                switch section {
                case .basic:
                    BasicChatSettingsView(chat: $draft)
                    
                case .model:
                    ModelSettingsSectionView(chat: $draft)
                    
                case .prediction:
                    PredictionSettingsSectionView(settings: $draft.settings.prediction)
                    
                case .prompt:
                    PromptSettingsSectionView(settings: $draft.settings.prompt)
                    
                case .sampling:
                    SamplingSettingsSectionView(settings: $draft.settings.sampling)
                    
                case .rag:
                    RagSettingsSectionView(settings: $draft.settings.rag)
                    
                case .documents:
                    DocumentsView(chat: draft)
                    
                case .advanced:
                    AdvancedSettingsSectionView(chat: $draft)
                }
            }
        }
        .navigationTitle(draft.title)
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
