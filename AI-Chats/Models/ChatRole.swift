import Foundation

enum ChatRole: String, Codable, CaseIterable, Identifiable {
    case user, assistant, system, rag

    var id: String { rawValue }

    var label: String {
        switch self {
        case .user: "You"
        case .assistant: "Assistant"
        case .system: "System"
        case .rag: "RAG"
        }
    }
}
