import SwiftUI

struct TemplatePicker: View {
    @Environment(ChatAppModel.self) private var appModel

    @Binding private var chat: ChatConfiguration
    
    init(_ chat: Binding<ChatConfiguration>) {
        _chat = chat
    }
    
    var body: some View {
        Picker("Template", selection: $chat.settings.modelSettingsTemplate) {
            if !ChatSettingsTemplate.builtIns.contains(where: { $0.name == chat.settings.modelSettingsTemplate }) {
                Text(chat.settings.modelSettingsTemplate)
                    .tag(chat.settings.modelSettingsTemplate)
                
                Divider()
            }
            
            ForEach(availableTemplates) {
                Text($0.name)
                    .tag($0.name)
            }
        }
        .onChange(of: chat.settings.modelSettingsTemplate) { _, newValue in
            if newValue == ChatSettingsTemplate.ggufTemplateName,
               let template = ggufTemplate {
                chat.applyTemplate(template)
                return
            }

            if let template = availableTemplates.first(where: { $0.name == newValue }) {
                chat.applyTemplate(template)
            }
        }
    }

    private var selectedModel: ModelFile? {
        guard let modelFileID = chat.modelFileID else { return nil }
        return appModel.modelFiles.first { $0.id == modelFileID }
    }

    private var availableTemplates: [ChatSettingsTemplate] {
        ChatSettingsTemplate.builtIns.filter {
            $0.name != ChatSettingsTemplate.ggufTemplateName || selectedModel?.ggufPromptTemplate != nil
        }
    }

    private var ggufTemplate: ChatSettingsTemplate? {
        guard let selectedModel,
              let promptTemplate = selectedModel.ggufPromptTemplate else { return nil }

        return ChatSettingsTemplate(
            ChatSettingsTemplate.ggufTemplateName,
            inference: selectedModel.family,
            contextLength: 4096,
            batchSize: 512,
            temperature: 0.7,
            topK: 40,
            topP: 0.9,
            useMetal: true,
            promptFormat: promptTemplate
        )
    }
}
