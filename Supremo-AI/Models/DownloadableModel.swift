import Foundation

struct DownloadableModel: Identifiable, Codable, Equatable {
    var id = UUID()
    var familyName: String
    var fileName: String
    var url: URL
    var quantization: String
    var sizeDescription: String
    var sizeBytes: Int?
    var inference: InferenceKind
    
    var displaySize: String {
        if let sizeBytes {
            sizeBytes.formatted(.byteCount(style: .file))
        } else {
            sizeDescription
        }
    }
    
    var familyDisplayName: String {
        let name = familyName.lowercased()
        
        if name.hasPrefix("gemma") {
            return "Gemma"
        } else if name.hasPrefix("phi") {
            return "Phi"
        } else if name.hasPrefix("bunny") {
            return "Bunny"
        } else if name.hasPrefix("llama") {
            return "Llama"
        } else if name.hasPrefix("moondream") {
            return "Moondream"
        } else {
            return familyName
        }
    }
}
