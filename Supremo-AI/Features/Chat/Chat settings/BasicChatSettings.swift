import ScrechKit

struct BasicChatSettings: View {
    @Binding private var chat: ChatConfiguration
    
    init(_ chat: Binding<ChatConfiguration>) {
        _chat = chat
    }
    
    var body: some View {
        Section {
            HStack {
                Text("Chat name")
                
                TextField("Title", text: $chat.title)
                    .multilineTextAlignment(.trailing)
                    .secondary()
            }
            
            LabeledContent("Model", value: chat.modelName)
        }
        
        Section {
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
            
            LabeledContent("Created", value: chat.createdAt, format: .dateTime)
            LabeledContent("Updated", value: chat.updatedAt, format: .dateTime)
        }
    }
}
