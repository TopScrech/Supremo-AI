import Foundation

struct RAGSettings: Codable, Equatable {
    var isEnabled = false
    var embeddingModel = EmbeddingModel.minilmMultiQA
    var maxAnswerCount = 3
    var chunkLength = 900
    var overlapLength = 120
}
