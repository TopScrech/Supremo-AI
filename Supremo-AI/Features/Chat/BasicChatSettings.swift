import SwiftUI

struct BasicChatSettings: View {
    @Binding var chat: ChatConfiguration
    
    var body: some View {
        Section("Basic Settings") {
            TextField("Title", text: $chat.title)
            TextField("Model name", text: $chat.modelName)
            
            Picker("Template", selection: $chat.settings.modelSettingsTemplate) {
                ForEach(ChatSettingsTemplate.builtIns) {
                    Text($0.name)
                        .tag($0.name)
                }
            }
            .onChange(of: chat.settings.modelSettingsTemplate) { _, newValue in
                if let template = ChatSettingsTemplate.builtIns.first(where: { $0.name == newValue }) {
                    chat.settings.modelSettingsTemplate = template.name
                    chat.settings.inference = template.inference
                    chat.settings.prediction.contextLength = template.contextLength
                    chat.settings.prediction.batchSize = template.batchSize
                    chat.settings.prediction.useMetal = template.useMetal
                    chat.settings.sampling.temperature = template.temperature
                    chat.settings.sampling.topK = template.topK
                    chat.settings.sampling.topP = template.topP
                    chat.settings.prompt.promptFormat = template.promptFormat
                }
            }
            
            Picker("Chat Style", selection: $chat.settings.style) {
                ForEach(ChatStyle.allCases) {
                    Text($0.label).tag($0)
                }
            }
        }
    }
}
