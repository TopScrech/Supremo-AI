import AppIntents
import Foundation

struct AskLocalChatIntent: AppIntent {
    nonisolated static let title: LocalizedStringResource = "Ask Local LLM"
    nonisolated static let description = IntentDescription("Send a prompt to the default local chat")
    nonisolated static let openAppWhenRun = false

    @Parameter(title: "Prompt")
    var prompt: String

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let store = JSONFileStore()
        let chats = (try? store.load([ChatConfiguration].self, from: "chats.json")) ?? [ChatConfiguration.sample]
        let chat = chats.first ?? .sample
        let text = previewResponse(prompt: prompt, chat: chat)
        return .result(value: text)
    }

    private func previewResponse(prompt: String, chat: ChatConfiguration) -> String {
        [
            "Configured chat: \(chat.title)",
            "Model: \(chat.modelName)",
            "Prompt: \(prompt)",
            "Connect llmfarm_core.swift to run this shortcut with real offline inference"
        ].joined(separator: "\n\n")
    }
}
