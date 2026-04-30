import Foundation

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    var role: ChatRole
    var text: String
    var targetText: String?
    var createdAt = Date()
    var attachmentName: String?
    var generationStartedAt: Date?
    var firstTokenAt: Date?
    var generationCompletedAt: Date?
    
    init(role: ChatRole, text: String, targetText: String? = nil, createdAt: Date = Date(), attachmentName: String? = nil, generationStartedAt: Date? = nil, firstTokenAt: Date? = nil, generationCompletedAt: Date? = nil) {
        self.role = role
        self.text = text
        self.targetText = targetText
        self.createdAt = createdAt
        self.attachmentName = attachmentName
        self.generationStartedAt = generationStartedAt
        self.firstTokenAt = firstTokenAt
        self.generationCompletedAt = generationCompletedAt
    }
    
    var timeToFirstToken: TimeInterval? {
        guard let generationStartedAt, let firstTokenAt else { return nil }
        return firstTokenAt.timeIntervalSince(generationStartedAt)
    }
    
    var tokensPerSecond: Double? {
        guard let firstTokenAt else { return nil }
        let output = targetText ?? text
        let tokenCount = ChatMessageTokenCounter.count(in: output)
        guard tokenCount > 0 else { return nil }
        
        let endDate = generationCompletedAt ?? Date()
        let generationDuration = endDate.timeIntervalSince(firstTokenAt)
        guard generationDuration > 0 else { return nil }
        
        return Double(tokenCount) / generationDuration
    }
}
