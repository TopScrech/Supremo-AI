import AppIntents

struct AskLocalChatIntent: AppIntent {
    nonisolated static let title: LocalizedStringResource = "Ask Local LLM"
    nonisolated static let description = IntentDescription("Send a prompt to the default local chat")
    nonisolated static let openAppWhenRun = false
    
    @Parameter(title: "Prompt")
    var prompt: String

    @Parameter(title: "Model")
    var model: LocalModelEntity?
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await ShortcutInferenceService().response(prompt: prompt, modelID: model?.id)
        return .result(value: response)
    }
}
