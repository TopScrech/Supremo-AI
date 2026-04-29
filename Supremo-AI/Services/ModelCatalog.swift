import Foundation

struct ModelCatalog {
    static let featured: [DownloadableModel] = [
        model(family: "Llama 3.2 Instruct 1B", url: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF", versionPrefix: "Llama-3.2-1B-Instruct", inference: .llama),
        model(family: "Gemma 4 E2B Instruct", url: "https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF", versionPrefix: "gemma-4-E2B-it", inference: .gemma),
        model(family: "Gemma 4 E4B Instruct", url: "https://huggingface.co/dragonboat/gemma-4-E4B-it-GGUF", versionPrefix: "gemma-4-E4B-it", inference: .gemma),
        model(family: "Gemma 3 1B Instruct", url: "https://huggingface.co/matrixportalx/gemma-3-1b-it-GGUF", versionPrefix: "gemma-3-1b-it", inference: .gemma),
        model(family: "Gemma 2 2B", url: "https://huggingface.co/guinmoon/LLMFarm_Models", versionPrefix: "gemma 2b_it_v2", inference: .gemma),
        model(family: "Qwen3.6 35B A3B", url: "https://huggingface.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF", versionPrefix: "Qwen_Qwen3.6-35B-A3B", inference: .qwen),
        model(family: "DeepSeek R1 0528 Qwen3 8B", url: "https://huggingface.co/guynich/DeepSeek-R1-0528-Qwen3-8B_Q4_K_M", versionPrefix: "deepseek-r1-0528-qwen3-8b", inference: .deepseek),
        model(family: "Nemotron 3 Nano 4B", url: "https://huggingface.co/lmstudio-community/NVIDIA-Nemotron-3-Nano-4B-GGUF", versionPrefix: "NVIDIA-Nemotron-3-Nano-4B", inference: .nemotron),
        model(family: "LFM2.5 1.2B Instruct", url: "https://huggingface.co/lmstudio-community/LFM2.5-1.2B-Instruct-GGUF", versionPrefix: "LFM2.5-1.2B-Instruct", inference: .lfm2),
        model(family: "RNJ 1 Instruct", url: "https://huggingface.co/lmstudio-community/rnj-1-instruct-GGUF", versionPrefix: "rnj-1-instruct", inference: .gemma),
        model(family: "Ministral 3 3B Instruct", url: "https://huggingface.co/lmstudio-community/Ministral-3-3B-Instruct-2512-GGUF", versionPrefix: "Ministral-3-3B-Instruct-2512", inference: .mistral),
        model(family: "NSFW 13B SFT", url: "https://huggingface.co/mzwing/NSFW_13B_sft-GGUF", versionPrefix: "NSFW_13B_sft", inference: .baichuan),
        model(family: "Phi-3.5 mini instruct", url: "https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF", versionPrefix: "Phi-3.5-mini-instruct", inference: .phi),
        model(family: "Phi-4 Mini Reasoning", url: "https://huggingface.co/lmstudio-community/Phi-4-mini-reasoning-GGUF", versionPrefix: "Phi-4-mini-reasoning", inference: .phi),
        model(family: "Phi-4 Reasoning Plus", url: "https://huggingface.co/lmstudio-community/Phi-4-reasoning-plus-GGUF", versionPrefix: "Phi-4-reasoning-plus", inference: .phi),
        model(family: "Phi-4", url: "https://huggingface.co/lmstudio-community/phi-4-GGUF", versionPrefix: "phi-4", inference: .phi),
        model(family: "Bunny 1.0 4B", url: "https://huggingface.co/guinmoon/Bunny-v1_0-4B-GGUF", versionPrefix: "Bunny-v1_0-4B", inference: .llava),
        model(family: "Moondream 2", url: "https://huggingface.co/moondream/moondream2-gguf", versionPrefix: "moondream2-text-model", inference: .moondream)
    ]
    
    private static func model(family: String, url: String, versionPrefix: String, inference: InferenceKind) -> DownloadableModel {
        guard let url = URL(string: url) else {
            preconditionFailure("Invalid model URL")
        }
        
        return DownloadableModel(family: family, url: url, versionPrefix: versionPrefix, inference: inference)
    }
}
