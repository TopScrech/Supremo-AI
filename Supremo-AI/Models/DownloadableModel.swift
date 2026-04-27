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

    var familyDisplayName: String {
        let name = familyName.lowercased()

        switch true {
        case name.hasPrefix("gemma"): return "Gemma"
        case name.hasPrefix("phi"): return "Phi"
        case name.hasPrefix("bunny"): return "Bunny"
        case name.hasPrefix("llama"): return "Llama"
        case name.hasPrefix("qwen"): return "Qwen"
        case name.hasPrefix("deepseek"): return "DeepSeek"
        case name.hasPrefix("moondream"): return "Moondream"
        default: return familyName
        }
    }
}
