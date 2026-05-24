import Foundation

enum ChatRole: String, Identifiable, Codable, CaseIterable {
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
