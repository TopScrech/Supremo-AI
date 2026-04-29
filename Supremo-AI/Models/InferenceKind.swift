import Foundation

enum InferenceKind: String, Codable, CaseIterable, Identifiable {
    case llama, gemma, phi, gpt2, gptOSS, starcoder, falcon, mpt, bloom, stableLM, qwen, yi, deepseek, mixtral, mistral, nemotron, lfm2, plamo, mamba, rwkv, gptNeoX, llava, moondream, baichuan
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .stableLM: "StableLM"
        case .gptNeoX: "GPT-NeoX"
        case .gptOSS: "GPT OSS"
        case .lfm2: "LFM2"
        case .llava: "LLaVA"
        default: rawValue.capitalized
        }
    }
}
