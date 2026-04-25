import Foundation

struct ModelFile: Identifiable, Codable, Equatable {
    var id = UUID()
    var displayName: String
    var fileName: String
    var localURL: URL?
    var remoteURL: URL?
    var quantization: String
    var family: InferenceKind
    var isMultimodalProjector = false
    var isPartialDownload: Bool?
    
    var isAvailableLocally: Bool { localURL != nil && isPartialDownload != true }
}
