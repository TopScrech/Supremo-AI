import SwiftUI

struct ChatSettingsSectionContent: View {
    let section: ChatSettingsSection
    @Binding var chat: ChatConfiguration
    
    var body: some View {
        switch section {
        case .basic: BasicChatSettings($chat)
        case .prediction: PredictionSettingsSection($chat.settings.prediction)
        case .prompt: PromptSettingsSection($chat.settings.prompt)
        case .sampling: SamplingSettingsSection($chat.settings.sampling)
        case .rag: RAGSettingsSection($chat)
        }
    }
}
