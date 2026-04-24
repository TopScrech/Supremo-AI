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
}
