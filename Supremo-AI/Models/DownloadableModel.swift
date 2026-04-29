import Foundation

struct DownloadableModel: Identifiable, Codable, Equatable {
    var id = UUID()
    var family: String
    var fileName: String
    var url: URL
    var sourceURL: URL? = nil
    var quantization: String
    var sizeBytes: Int?
    var inference: InferenceKind
    var versionPrefix: String? = nil
    
    var displaySize: String {
        if let sizeBytes {
            sizeBytes.formatted(.byteCount(style: .file))
        } else {
            "-"
        }
    }
    
    var huggingFaceModelCardURL: URL? {
        let modelURL = sourceURL ?? url
        guard modelURL.host == "huggingface.co" else { return nil }
        
        let pathComponents = modelURL.pathComponents
        guard pathComponents.count >= 3 else { return nil }
        
        return URL(string: "https://huggingface.co/\(pathComponents[1])/\(pathComponents[2])")
    }
    
    var familyDisplayName: String {
        let name = family.lowercased()
        
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
        case name.hasPrefix("gpt"): return "GPT"
        default: return family
        }
    }
    
    var supportsVersionSelection: Bool {
        huggingFaceModelCardURL != nil && versionPrefix != nil
    }
    
    var versionSelectionID: String {
        if supportsVersionSelection, let huggingFaceModelCardURL {
            huggingFaceModelCardURL.absoluteString
        } else {
            fileName
        }
    }
    
    func matchesVersionFileName(_ fileName: String) -> Bool {
        guard fileName.hasSuffix(".gguf") else { return false }
        guard let versionPrefix else { return self.fileName == fileName }
        
        return normalizedVersionFileName(fileName).hasPrefix(normalizedVersionFileName(versionPrefix))
    }
    
    func downloadURL(for fileName: String) -> URL? {
        if self.fileName == fileName {
            return url
        }
        
        guard let huggingFaceModelCardURL else { return nil }
        
        return huggingFaceModelCardURL
            .appending(path: "resolve/main")
            .appending(path: fileName)
            .appending(queryItems: [
                URLQueryItem(name: "download", value: "true")
            ])
    }
    
    private func normalizedVersionFileName(_ fileName: String) -> String {
        fileName.lowercased()
            .replacing(" ", with: "")
            .replacing("-", with: "")
            .replacing("_", with: "")
            .replacing(".", with: "")
    }
}

extension DownloadableModel {
    init(_ family: String, url: URL, sourceURL: URL? = nil, versionPrefix: String, inference: InferenceKind) {
        self.init(
            family: family,
            fileName: versionPrefix,
            url: url,
            sourceURL: sourceURL,
            quantization: "GGUF",
            sizeBytes: nil,
            inference: inference,
            versionPrefix: versionPrefix
        )
    }
}
