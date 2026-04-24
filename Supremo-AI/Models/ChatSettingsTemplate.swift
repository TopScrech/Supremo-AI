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
    
    static let builtIns = [
        ChatSettingsTemplate(name: "Custom", inference: .llama, contextLength: 2048, batchSize: 512, temperature: 0.9, topK: 40, topP: 0.95, useMetal: true, promptFormat: "{prompt}"),
        ChatSettingsTemplate(name: "Llama 3 Instruct", inference: .llama, contextLength: 4096, batchSize: 512, temperature: 0.7, topK: 40, topP: 0.9, useMetal: true, promptFormat: "<|begin_of_text|><|start_header_id|>user<|end_header_id|>\n{prompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>"),
        ChatSettingsTemplate(name: "Gemma", inference: .gemma, contextLength: 4096, batchSize: 512, temperature: 0.8, topK: 40, topP: 0.95, useMetal: true, promptFormat: "<start_of_turn>user\n{prompt}<end_of_turn>\n<start_of_turn>model"),
        ChatSettingsTemplate(name: "Gemma 3", inference: .gemma, contextLength: 4096, batchSize: 512, temperature: 0.8, topK: 40, topP: 0.95, useMetal: true, promptFormat: "<start_of_turn>user\n{prompt}<end_of_turn>\n<start_of_turn>model\n"),
        ChatSettingsTemplate(name: "Phi", inference: .phi, contextLength: 4096, batchSize: 512, temperature: 0.7, topK: 40, topP: 0.9, useMetal: true, promptFormat: "<|user|>\n{prompt}<|end|>\n<|assistant|>"),
        ChatSettingsTemplate(name: "ChatML", inference: .llama, contextLength: 4096, batchSize: 512, temperature: 0.8, topK: 40, topP: 0.95, useMetal: true, promptFormat: "<|im_start|>user\n{prompt}<|im_end|>\n<|im_start|>assistant")
    ]
}
