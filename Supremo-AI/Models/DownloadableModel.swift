import Foundation

struct DownloadableModel: Identifiable, Codable, Equatable {
    var id = UUID()
    var family: String
    var fileName: String
    var url: URL
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
        guard url.host == "huggingface.co" else { return nil }
        
        let pathComponents = url.pathComponents
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
        default: return family
        }
    }
    
    var supportsVersionSelection: Bool {
        huggingFaceModelCardURL != nil && versionPrefix != nil
    }
    
    var versionSelectionID: String {
        if supportsVersionSelection, let huggingFaceModelCardURL {
            return huggingFaceModelCardURL.absoluteString
        }
        
        return fileName
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
    init(family: String, url: URL, versionPrefix: String, inference: InferenceKind) {
        self.init(
            family: family,
            fileName: versionPrefix,
            url: url,
            quantization: "GGUF",
            sizeBytes: nil,
            inference: inference,
            versionPrefix: versionPrefix
        )
    }
}
