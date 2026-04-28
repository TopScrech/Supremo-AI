import SwiftUI

struct RAGSettingsSection: View {
    @Binding private var chat: ChatConfiguration
    
    init(_ chat: Binding<ChatConfiguration>) {
        _chat = chat
    }
    
    var body: some View {
        Section {
            Picker("Embedding Model", selection: $chat.settings.rag.embeddingModel) {
                ForEach(EmbeddingModel.allCases) {
                    Text($0.label)
                        .tag($0)
                }
            }
            
            Stepper("Answers \(chat.settings.rag.maxAnswerCount)", value: $chat.settings.rag.maxAnswerCount, in: 1...12)
            Stepper("Chunk length \(chat.settings.rag.chunkLength)", value: $chat.settings.rag.chunkLength, in: 200...4000, step: 100)
            Stepper("Overlap \(chat.settings.rag.overlapLength)", value: $chat.settings.rag.overlapLength, in: 0...1000, step: 20)
        }
        
        DocumentsView(chat)
    }
}
