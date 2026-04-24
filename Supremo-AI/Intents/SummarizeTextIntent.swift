import AppIntents
import Foundation

struct SummarizeTextIntent: AppIntent {
    nonisolated static let title: LocalizedStringResource = "Summarize with Local LLM"
    nonisolated static let description = IntentDescription("Create a local summary preview")
    nonisolated static let openAppWhenRun = false

    @Parameter(title: "Text")
    var text: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let sentence = trimmed.split(separator: ".").first.map(String.init) ?? trimmed
        return .result(value: "Summary preview: \(sentence)")
    }
}
