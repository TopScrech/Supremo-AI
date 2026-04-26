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
                    chat.applyTemplate(template)
                }
            }
            
            Picker("Chat Style", selection: $chat.settings.style) {
                ForEach(ChatStyle.allCases) {
                    Text($0.label).tag($0)
                }
            }
            
            Toggle("Enable RAG", isOn: $chat.settings.rag.isEnabled)
        }
    }
}
