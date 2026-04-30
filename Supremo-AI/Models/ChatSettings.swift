import Foundation

struct ChatSettings: Codable, Equatable {
    var inference = InferenceKind.llama
    var prediction = PredictionSettings()
    var sampling = SamplingSettings()
    var prompt = PromptSettings()
    var rag = RAGSettings()
    var style = ChatStyle.balanced
    var modelSettingsTemplate = "Llama 3 Instruct"
    var includesChatHistory = true
    
    enum CodingKeys: String, CodingKey {
        case inference, prediction, sampling, prompt, rag, style, modelSettingsTemplate, includesChatHistory
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        inference = try container.decodeIfPresent(InferenceKind.self, forKey: .inference) ?? .llama
        prediction = try container.decodeIfPresent(PredictionSettings.self, forKey: .prediction) ?? PredictionSettings()
        sampling = try container.decodeIfPresent(SamplingSettings.self, forKey: .sampling) ?? SamplingSettings()
        prompt = try container.decodeIfPresent(PromptSettings.self, forKey: .prompt) ?? PromptSettings()
        rag = try container.decodeIfPresent(RAGSettings.self, forKey: .rag) ?? RAGSettings()
        style = try container.decodeIfPresent(ChatStyle.self, forKey: .style) ?? .balanced
        modelSettingsTemplate = try container.decodeIfPresent(String.self, forKey: .modelSettingsTemplate) ?? "Llama 3 Instruct"
        includesChatHistory = try container.decodeIfPresent(Bool.self, forKey: .includesChatHistory) ?? true
    }
}
