import ScrechKit

struct BasicChatSettings: View {
    @Binding var chat: ChatConfiguration
    
    var body: some View {
        Section("Basic Settings") {
            TextField("Title", text: $chat.title)
            TextField("Model name", text: $chat.modelName)
            
            Picker("Inference", selection: $chat.settings.inference) {
                ForEach(InferenceKind.allCases) {
                    Text($0.label)
                        .tag($0)
                }
            }
            
            TemplatePicker($chat)
            
            Picker("Chat Style", selection: $chat.settings.style) {
                ForEach(ChatStyle.allCases) {
                    Text($0.label)
                        .tag($0)
                }
            }
            
            Toggle("RAG", isOn: $chat.settings.rag.isEnabled)
            Toggle("Metal", isOn: $chat.settings.prediction.useMetal)
            Toggle("CLIP Metal", isOn: $chat.settings.prediction.useClipMetal)
        }
        
        Section("Info") {
            Text(chat.id.uuidString)
                .caption()
                .textSelection(.enabled)
            
            LabeledContent("Created", value: chat.createdAt, format: .dateTime)
            LabeledContent("Updated", value: chat.updatedAt, format: .dateTime)
        }
    }
}
