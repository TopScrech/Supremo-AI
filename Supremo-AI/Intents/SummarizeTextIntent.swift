import AppIntents
import Foundation

struct SummarizeTextIntent: AppIntent {
    nonisolated static let title: LocalizedStringResource = "Summarize with Local LLM"
    nonisolated static let description = IntentDescription("Summarize text with a local model")
    nonisolated static let openAppWhenRun = false
    
    @Parameter(title: "Text")
    var text: String
    
    @Parameter(title: "Model")
    var model: LocalModelEntity?
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await ShortcutInferenceService().summary(text: text, modelID: model?.id)
        return .result(value: response)
    }
}
