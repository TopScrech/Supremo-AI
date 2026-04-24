import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    var role: ChatRole
    var text: String
    var createdAt = Date()
    var attachmentName: String?
}
