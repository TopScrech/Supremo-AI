import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    var role: ChatRole
    var text: String
    var targetText: String?
    var createdAt = Date()
    var attachmentName: String?
    
    init(role: ChatRole, text: String, targetText: String? = nil, createdAt: Date = Date(), attachmentName: String? = nil) {
        self.role = role
        self.text = text
        self.targetText = targetText
        self.createdAt = createdAt
        self.attachmentName = attachmentName
    }
}
