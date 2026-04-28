import SwiftUI

struct TemplatePicker: View {
    @Binding private var chat: ChatConfiguration
    
    init(_ chat: Binding<ChatConfiguration>) {
        _chat = chat
    }
    
    var body: some View {
        Picker("Template", selection: $chat.settings.modelSettingsTemplate) {
            if !ChatSettingsTemplate.builtIns.contains(where: { $0.name == chat.settings.modelSettingsTemplate }) {
                Text(chat.settings.modelSettingsTemplate)
                    .tag(chat.settings.modelSettingsTemplate)
            }
            
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
    }
}
