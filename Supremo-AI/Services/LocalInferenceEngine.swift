import Foundation
import llmfarm_core

protocol LocalInferenceEngine {
    var isAvailable: Bool { get }
    func response(for prompt: String, chat: ChatConfiguration, context: [RAGDocument]) async throws -> String
}

enum InferenceEngineError: LocalizedError {
    case backendUnavailable
    
    var errorDescription: String? {
        switch self {
        case .backendUnavailable:
            "The native inference backend could not load the selected model"
        }
    }
}

struct LLMFarmInferenceEngine: LocalInferenceEngine {
    let isAvailable = true
    
    func response(for prompt: String, chat: ChatConfiguration, context: [RAGDocument]) async throws -> String {
        guard let modelURL = chat.modelFileURL else {
            throw InferenceEngineError.backendUnavailable
        }
        
        let input = promptWithRAG(prompt: prompt, context: context)
        let ai = AI(_modelPath: modelURL.path(), _chatName: chat.id.uuidString)
        let contextParams = makeContextParams(for: chat)
        let sampleParams = makeSampleParams(for: chat)
        
        ai.initModel(contextParams.model_inference, contextParams: contextParams)
        guard let model = ai.model else {
            throw InferenceEngineError.backendUnavailable
        }
        
        model.sampleParams = sampleParams
        model.contextParams = contextParams
        try ai.loadModel_sync()
        
        var output = ""
        _ = try model.Predict(
            input,
            { token, _ in
                output += token
                return output.count >= chat.settings.prediction.maxTokens * 8
            },
            system_prompt: chat.settings.prompt.systemPrompt.isEmpty ? nil : chat.settings.prompt.systemPrompt
        )
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func promptWithRAG(prompt: String, context: [RAGDocument]) -> String {
        guard !context.isEmpty else { return prompt }
        
        let contextText = context
            .map { "\($0.title)\n\($0.text)" }
            .joined(separator: "\n\n")
        
        return """
        Use the following context when it is relevant.
        
        \(contextText)
        
        User prompt:
        \(prompt)
        """
    }
    
    private func makeContextParams(for chat: ChatConfiguration) -> ModelAndContextParams {
        var params = ModelAndContextParams.default
        params.model_inference = modelInference(for: chat)
        params.context = Int32(chat.settings.prediction.contextLength)
        params.n_predict = Int32(chat.settings.prediction.maxTokens)
        params.n_threads = chat.settings.prediction.threadCount == 0 ? params.processorsConunt : Int32(chat.settings.prediction.threadCount)
        params.use_metal = chat.settings.prediction.useMetal
        params.use_clip_metal = chat.settings.prediction.useClipMetal
        params.useMMap = chat.settings.prediction.mmap
        params.useMlock = chat.settings.prediction.mlock
        params.flash_attn = chat.settings.prediction.flashAttention
        params.add_bos_token = chat.settings.prediction.addBosToken
        params.add_eos_token = chat.settings.prediction.addEosToken
        params.parse_special_tokens = chat.settings.prediction.parseSpecialTokens
        params.save_load_state = chat.settings.prediction.restoreContextState
        params.custom_prompt_format = chat.settings.prompt.promptFormat
        params.promptFormat = .Custom
        params.system_prompt = chat.settings.prompt.systemPrompt
        params.reverse_prompt = chat.settings.prompt.reversePrompt
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        params.skip_tokens_str = chat.settings.prompt.skipTokens
        return params
    }
    
    private func makeSampleParams(for chat: ChatConfiguration) -> ModelSampleParams {
        var params = ModelSampleParams.default
        params.n_batch = Int32(chat.settings.prediction.batchSize)
        params.temp = Float(chat.settings.sampling.temperature)
        params.top_k = Int32(chat.settings.sampling.topK)
        params.top_p = Float(chat.settings.sampling.topP)
        params.tfs_z = Float(chat.settings.sampling.tailFreeSampling)
        params.typical_p = Float(chat.settings.sampling.typicalP)
        params.repeat_last_n = Int32(chat.settings.sampling.repeatLastN)
        params.repeat_penalty = Float(chat.settings.sampling.repeatPenalty)
        params.mirostat_tau = Float(chat.settings.sampling.mirostatTau)
        params.mirostat_eta = Float(chat.settings.sampling.mirostatEta)
        params.mirostat = mirostatValue(for: chat.settings.sampling.method)
        return params
    }
    
    private func modelInference(for chat: ChatConfiguration) -> ModelInference {
        switch chat.settings.inference {
        case .llava, .moondream:
                .LLama_mm
        default:
                .LLama_gguf
        }
    }
    
    private func mirostatValue(for method: SamplingMethod) -> Int32 {
        switch method {
        case .mirostat: 1
        case .mirostatV2: 2
        default: 0
        }
    }
}
