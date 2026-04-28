import Foundation

enum ShortcutInferenceError: LocalizedError {
    case emptyPrompt, missingChat, missingModel, emptyResponse

    var errorDescription: String? {
        switch self {
        case .emptyPrompt: "Enter a prompt before running the shortcut"
        case .missingChat: "Create a chat before running the shortcut"
        case .missingModel: "Install or select a local model before running the shortcut"
        case .emptyResponse: "The local model returned an empty response"
        }
    }
}
