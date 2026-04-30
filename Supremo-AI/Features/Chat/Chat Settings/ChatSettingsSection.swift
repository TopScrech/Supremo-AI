import Foundation

enum ChatSettingsSection: String, CaseIterable, Identifiable {
    case basic, prediction, prompt, sampling, rag
    
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    
    var systemImage: String {
        switch self {
        case .basic: "slider.horizontal.3"
        case .prediction: "speedometer"
        case .prompt: "text.quote"
        case .sampling: "waveform.path.ecg"
        case .rag: "doc.text.magnifyingglass"
        }
    }
}
