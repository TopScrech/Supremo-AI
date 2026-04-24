import Foundation

struct ChatSettings: Codable, Equatable {
    var inference = InferenceKind.llama
    var prediction = PredictionSettings()
    var sampling = SamplingSettings()
    var prompt = PromptSettings()
    var rag = RAGSettings()
    var style = ChatStyle.balanced
    var modelSettingsTemplate = "Llama 3 Instruct"
}
