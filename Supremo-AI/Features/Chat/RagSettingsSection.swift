import SwiftUI

struct RagSettingsSection: View {
    @Binding var settings: RAGSettings
    
    var body: some View {
        Section("RAG") {
            Picker("Embedding Model", selection: $settings.embeddingModel) {
                ForEach(EmbeddingModel.allCases) {
                    Text($0.label)
                        .tag($0)
                }
            }
            
            Stepper("Answers \(settings.maxAnswerCount)", value: $settings.maxAnswerCount, in: 1...12)
            Stepper("Chunk length \(settings.chunkLength)", value: $settings.chunkLength, in: 200...4000, step: 100)
            Stepper("Overlap \(settings.overlapLength)", value: $settings.overlapLength, in: 0...1000, step: 20)
        }
    }
}
