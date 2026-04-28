import Foundation

struct ChatSettingsTemplate: Identifiable, Codable, Hashable {
    static let ggufTemplateName = "built-in"
    
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
        ChatSettingsTemplate(ggufTemplateName, inference: .llama, contextLength: 4096, batchSize: 512, temperature: 0.7, topK: 40, topP: 0.9, useMetal: true, promptFormat: "{prompt}"),
        ChatSettingsTemplate("Llama 3 Instruct", inference: .llama, contextLength: 4096, batchSize: 512, temperature: 0.7, topK: 40, topP: 0.9, useMetal: true, promptFormat: "<|begin_of_text|><|start_header_id|>user<|end_header_id|>\n{prompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>"),
        ChatSettingsTemplate("Gemma 2", inference: .gemma, contextLength: 4096, batchSize: 512, temperature: 0.8, topK: 40, topP: 0.95, useMetal: true, promptFormat: "<start_of_turn>user\n{prompt}<end_of_turn>\n<start_of_turn>model"),
        ChatSettingsTemplate("Gemma 3", inference: .gemma, contextLength: 4096, batchSize: 512, temperature: 0.8, topK: 40, topP: 0.95, useMetal: true, promptFormat: "<start_of_turn>user\n{prompt}<end_of_turn>\n<start_of_turn>model\n"),
        ChatSettingsTemplate("Gemma 4", inference: .gemma, contextLength: 4096, batchSize: 512, temperature: 1, topK: 64, topP: 0.95, useMetal: true, promptFormat: "<|turn>user\n{prompt}<turn|>\n<|turn>model\n<|channel>thought\n<channel|>"),
        ChatSettingsTemplate("Phi", inference: .phi, contextLength: 4096, batchSize: 512, temperature: 0.7, topK: 40, topP: 0.9, useMetal: true, promptFormat: "<|user|>\n{prompt}<|end|>\n<|assistant|>"),
        ChatSettingsTemplate("Qwen", inference: .qwen, contextLength: 4096, batchSize: 512, temperature: 0.7, topK: 40, topP: 0.9, useMetal: true, promptFormat: "<|im_start|>user\n{prompt}<|im_end|>\n<|im_start|>assistant\n"),
        ChatSettingsTemplate("DeepSeek R1", inference: .deepseek, contextLength: 4096, batchSize: 512, temperature: 0.6, topK: 40, topP: 0.95, useMetal: true, promptFormat: "<｜begin▁of▁sentence｜><｜User｜>{prompt}<｜Assistant｜>"),
        ChatSettingsTemplate("Bunny", inference: .llava, contextLength: 4096, batchSize: 512, temperature: 0, topK: 40, topP: 0.95, useMetal: true, promptFormat: "A chat between a curious user and an artificial intelligence assistant. The assistant gives helpful, detailed, and polite answers to the user's questions. USER: <image>\n{prompt} ASSISTANT:"),
        ChatSettingsTemplate("Moondream 2", inference: .moondream, contextLength: 2048, batchSize: 512, temperature: 0, topK: 40, topP: 0.95, useMetal: true, promptFormat: "A chat between a curious user and an artificial intelligence assistant. The assistant gives helpful, detailed, and polite answers to the user's questions. USER: {prompt} ASSISTANT:")
        // ChatSettingsTemplate("ChatML", inference: .llama, contextLength: 4096, batchSize: 512, temperature: 0.8, topK: 40, topP: 0.95, useMetal: true, promptFormat: "<|im_start|>user\n{prompt}<|im_end|>\n<|im_start|>assistant")
    ]
    
    static func automaticTemplate(for model: ModelFile) -> ChatSettingsTemplate? {
        let modelName = model.displayName
        
        if modelName.localizedStandardContains("gemma 4") || modelName.localizedStandardContains("gemma-4") {
            return builtIns.first { $0.name == "Gemma 4" }
        }
        
        if let promptTemplate = model.ggufPromptTemplate {
            return ChatSettingsTemplate(ggufTemplateName, inference: model.family, contextLength: 4096, batchSize: 512, temperature: 0.7, topK: 40, topP: 0.9, useMetal: true, promptFormat: promptTemplate)
        }
        
        if let promptTemplate = model.promptTemplate {
            return ChatSettingsTemplate("Dynamic", inference: model.family, contextLength: 4096, batchSize: 512, temperature: 0.7, topK: 40, topP: 0.9, useMetal: true, promptFormat: promptTemplate)
        }
        
        if modelName.localizedStandardContains("gemma 3") || modelName.localizedStandardContains("gemma-3") {
            return builtIns.first { $0.name == "Gemma 3" }
        }
        
        if modelName.localizedStandardContains("gemma 2") || modelName.localizedStandardContains("gemma v2") || modelName.localizedStandardContains("gemma_2b") {
            return builtIns.first { $0.name == "Gemma 2" }
        }
        
        if modelName.localizedStandardContains("phi") {
            return builtIns.first { $0.name == "Phi" }
        }
        
        if modelName.localizedStandardContains("deepseek") {
            return builtIns.first { $0.name == "DeepSeek R1" }
        }
        
        if modelName.localizedStandardContains("qwen") {
            return builtIns.first { $0.name == "Qwen" }
        }
        
        if modelName.localizedStandardContains("bunny") {
            return builtIns.first { $0.name == "Bunny" }
        }
        
        if modelName.localizedStandardContains("moondream") {
            return builtIns.first { $0.name == "Moondream 2" }
        }
        
        if modelName.localizedStandardContains("llama") {
            return builtIns.first { $0.name == "Llama 3 Instruct" }
        }
        
        return builtIns.first {
            $0.inference == model.family && $0.name != "Custom"
        }
    }
}
