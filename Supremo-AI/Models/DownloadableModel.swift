import Foundation

struct DownloadableModel: Identifiable, Codable, Equatable {
    var id = UUID()
    var familyName: String
    var fileName: String
    var url: URL
    var quantization: String
    var sizeBytes: Int?
    var inference: InferenceKind

    var displaySize: String {
        if let sizeBytes {
            sizeBytes.formatted(.byteCount(style: .file))
        } else {
            "-"
        }
    }
    
    var huggingFaceModelCardURL: URL? {
        guard url.host == "huggingface.co" else { return nil }
        
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 3 else { return nil }
        
        return URL(string: "https://huggingface.co/\(pathComponents[1])/\(pathComponents[2])")
    }

    var familyDisplayName: String {
        let name = familyName.lowercased()

        switch true {
        case name.hasPrefix("gemma"): return "Gemma"
        case name.hasPrefix("phi"): return "Phi"
        case name.hasPrefix("bunny"): return "Bunny"
        case name.hasPrefix("llama"): return "Llama"
        case name.hasPrefix("qwen"): return "Qwen"
        case name.hasPrefix("deepseek"): return "DeepSeek"
        case name.hasPrefix("nemotron"): return "Nemotron"
        case name.hasPrefix("lfm"): return "LFM"
        case name.hasPrefix("ministral"): return "Ministral"
        case name.hasPrefix("rnj"): return "RNJ"
        case name.hasPrefix("moondream"): return "Moondream"
        default: return familyName
        }
    }

    var supportsVersionSelection: Bool {
        huggingFaceModelCardURL != nil
    }

    var versionSelectionID: String {
        if supportsVersionSelection, let huggingFaceModelCardURL {
            return huggingFaceModelCardURL.absoluteString
        }

        return fileName
    }
}
