import Foundation

struct ChatConfiguration: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var modelName: String
    var modelFileID: UUID?
    var settings = ChatSettings()
    var messages: [ChatMessage] = []
    var documents: [RAGDocument] = []
    var createdAt = Date()
    var updatedAt = Date()
    var modelFileURL: URL?

    static var sample: ChatConfiguration {
        ChatConfiguration(title: "Local Assistant", modelName: "No model selected")
    }
}
