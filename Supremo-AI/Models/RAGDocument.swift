import Foundation

struct RAGDocument: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var text: String
    var sourceURL: URL?
    var importedAt = Date()
}
