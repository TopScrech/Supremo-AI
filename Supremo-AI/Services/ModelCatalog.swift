import Foundation

struct ModelCatalog {
    static let featured: [DownloadableModel] = [
        model(familyName: "Llama 3.2 Instruct 1B", fileName: "Llama-3.2-1B-Instruct-Q5_K_M.gguf", urlString: "https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q5_K_M.gguf?download=true", quantization: "Q5_K_M", sizeDescription: "About 1 GB", sizeBytes: 1_050_000_000, inference: .llama),
        model(familyName: "Gemma 4 E2B Instruct", fileName: "gemma-4-E2B-it-Q4_K_M.gguf", urlString: "https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-Q4_K_M.gguf?download=true", quantization: "Q4_K_M", sizeDescription: "3.1 GB", sizeBytes: 3_106_735_776, inference: .gemma),
        model(familyName: "Gemma 4 E2B Instruct", fileName: "gemma-4-E2B-it-Q5_K_M.gguf", urlString: "https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-Q5_K_M.gguf?download=true", quantization: "Q5_K_M", sizeDescription: "3.4 GB", sizeBytes: 3_356_034_720, inference: .gemma),
        model(familyName: "Gemma 4 E4B Instruct", fileName: "gemma-4-E4B-it-Q4_K_M.gguf", urlString: "https://huggingface.co/dragonboat/gemma-4-E4B-it-GGUF/resolve/main/gemma-4-E4B-it-Q4_K_M.gguf?download=true", quantization: "Q4_K_M", sizeDescription: "5 GB", sizeBytes: 4_977_164_672, inference: .gemma),
        model(familyName: "Gemma 4 E4B Instruct", fileName: "gemma-4-E4B-it-Q5_K_M.gguf", urlString: "https://huggingface.co/dragonboat/gemma-4-E4B-it-GGUF/resolve/main/gemma-4-E4B-it-Q5_K_M.gguf?download=true", quantization: "Q5_K_M", sizeDescription: "5.5 GB", sizeBytes: 5_481_791_872, inference: .gemma),
        model(familyName: "Gemma 4 26B A4B Instruct", fileName: "gemma-4-26B-A4B-it-Q4_K_M.gguf", urlString: "https://huggingface.co/lmstudio-community/gemma-4-26B-A4B-it-GGUF/resolve/main/gemma-4-26B-A4B-it-Q4_K_M.gguf?download=true", quantization: "Q4_K_M", sizeDescription: "16.8 GB", sizeBytes: 16_796_015_040, inference: .gemma),
        model(familyName: "Gemma v2 2B", fileName: "gemma_2b_it_v2_Q5_K_S.gguf", urlString: "https://huggingface.co/guinmoon/LLMFarm_Models/resolve/main/gemma%202b_it_v2_Q5_K_S.gguf", quantization: "Q5_K_S", sizeDescription: "About 1.8 GB", sizeBytes: 1_800_000_000, inference: .gemma),
        model(familyName: "Phi-3.5 mini instruct", fileName: "Phi-3.5-mini-instruct-Q4_K_S.gguf", urlString: "https://huggingface.co/bartowski/Phi-3.5-mini-instruct-GGUF/resolve/main/Phi-3.5-mini-instruct-Q4_K_S.gguf?download=true", quantization: "Q4_K_S", sizeDescription: "About 2.2 GB", sizeBytes: 2_200_000_000, inference: .phi),
        model(familyName: "Bunny 1.0 4B", fileName: "Bunny-v1_0-4B-Q4_K_S.gguf", urlString: "https://huggingface.co/guinmoon/Bunny-v1_0-4B-GGUF/resolve/main/Bunny-v1_0-4B-Q4_K_S.gguf?download=true", quantization: "Q4_K_S", sizeDescription: "About 2.4 GB", sizeBytes: 2_400_000_000, inference: .llava),
        model(familyName: "Moondream 2", fileName: "moondream2-text-model-f16.gguf", urlString: "https://huggingface.co/vikhyatk/moondream2", quantization: "F16", sizeDescription: "Size varies", sizeBytes: nil, inference: .moondream)
    ]
    
    private static func model(familyName: String, fileName: String, urlString: String, quantization: String, sizeDescription: String, sizeBytes: Int?, inference: InferenceKind) -> DownloadableModel {
        guard let url = URL(string: urlString) else {
            preconditionFailure("Invalid model URL")
        }
        
        return DownloadableModel(familyName: familyName, fileName: fileName, url: url, quantization: quantization, sizeDescription: sizeDescription, sizeBytes: sizeBytes, inference: inference)
    }
}
