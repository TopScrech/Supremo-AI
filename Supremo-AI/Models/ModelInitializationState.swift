import Foundation

enum ModelInitializationState: Equatable {
    case idle, initializing, ready, failed
    
    var title: String {
        switch self {
        case .initializing: "Initializing Model"
        case .failed: "Model Initialization Failed"
        case .ready: "Model Ready"
        case .idle: "Initialize Model"
        }
    }
    
    var systemImage: String {
        switch self {
        case .initializing: "cpu"
        case .failed: "exclamationmark.triangle"
        case .ready: "checkmark.circle"
        case .idle: "power"
        }
    }
}
