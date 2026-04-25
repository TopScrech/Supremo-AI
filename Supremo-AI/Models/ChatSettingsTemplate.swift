import Foundation

struct ChatSettingsTemplate: Identifiable, Codable, Hashable {
    var id: String { name }
    var name: String
    var inference: InferenceKind
    var contextLength: Int
    var batchSize: Int
    var temperature: Double
    var topK: Int
    var topP: Double
    var useMetal: Bool
    var promptFormat: String
    
    init(_ name: String, inference: InferenceKind, contextLength: Int, batchSize: Int, temperature: Double, topK: Int, topP: Double, useMetal: Bool, promptFormat: String) {
        self.name = name
        self.inference = inference
        self.contextLength = contextLength
        self.batchSize = batchSize
        self.temperature = temperature
        self.topK = topK
        self.topP = topP
        self.useMetal = useMetal
        self.promptFormat = promptFormat
    }
    
    static let builtIns = [
        ChatSettingsTemplate("Custom", inference: .llama, contextLength: 2048, batchSize: 512, temperature: 0.9, topK: 40, topP: 0.95, useMetal: true, promptFormat: "{prompt}"),
        ChatSettingsTemplate("Llama 3 Instruct", inference: .llama, contextLength: 4096, batchSize: 512, temperature: 0.7, topK: 40, topP: 0.9, useMetal: true, promptFormat: "<|begin_of_text|><|start_header_id|>user<|end_header_id|>\n{prompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>"),
        ChatSettingsTemplate("Gemma 2", inference: .gemma, contextLength: 4096, batchSize: 512, temperature: 0.8, topK: 40, topP: 0.95, useMetal: true, promptFormat: "<start_of_turn>user\n{prompt}<end_of_turn>\n<start_of_turn>model"),
        ChatSettingsTemplate("Gemma 3", inference: .gemma, contextLength: 4096, batchSize: 512, temperature: 0.8, topK: 40, topP: 0.95, useMetal: true, promptFormat: "<start_of_turn>user\n{prompt}<end_of_turn>\n<start_of_turn>model\n"),
        ChatSettingsTemplate("Gemma 4", inference: .gemma, contextLength: 4096, batchSize: 512, temperature: 1, topK: 64, topP: 0.95, useMetal: true, promptFormat: "<|turn>user\n{prompt}<turn|>\n<|turn>model\n<|channel>thought\n<channel|>"),
        ChatSettingsTemplate("Phi", inference: .phi, contextLength: 4096, batchSize: 512, temperature: 0.7, topK: 40, topP: 0.9, useMetal: true, promptFormat: "<|user|>\n{prompt}<|end|>\n<|assistant|>")
        // ChatSettingsTemplate("ChatML", inference: .llama, contextLength: 4096, batchSize: 512, temperature: 0.8, topK: 40, topP: 0.95, useMetal: true, promptFormat: "<|im_start|>user\n{prompt}<|im_end|>\n<|im_start|>assistant")
    ]
}
