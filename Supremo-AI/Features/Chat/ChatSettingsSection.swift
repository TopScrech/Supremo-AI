import Foundation

enum ChatSettingsSection: String, CaseIterable, Identifiable {
    case basic, prediction, prompt, sampling, rag
    
    var id: String { rawValue }
    
    var label: String { rawValue.capitalized }
}
