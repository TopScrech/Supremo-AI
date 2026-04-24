import Foundation

enum ChatSettingsSection: String, CaseIterable, Identifiable {
    case basic, model, prediction, prompt, sampling, rag, documents, advanced

    var id: String { rawValue }

    var label: String { rawValue.capitalized }
}
