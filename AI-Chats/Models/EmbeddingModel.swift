import Foundation

enum EmbeddingModel: String, Codable, CaseIterable, Identifiable {
    case minilmMultiQA, e5Small, bgeSmall

    var id: String { rawValue }

    var label: String {
        switch self {
        case .minilmMultiQA: "MiniLM Multi QA"
        case .e5Small: "E5 Small"
        case .bgeSmall: "BGE Small"
        }
    }
}
