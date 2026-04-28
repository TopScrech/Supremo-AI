import SwiftUI

struct PromptSettingsSection: View {
    @Binding var settings: PromptSettings
    
    var body: some View {
        TextField("System prompt", text: $settings.systemPrompt, axis: .vertical)
            .lineLimit(2...6)
        
        TextField("Prompt format", text: $settings.promptFormat, axis: .vertical)
            .lineLimit(3...8)
        
        TextField("Reverse prompt", text: $settings.reversePrompt)
        TextField("Skip tokens", text: $settings.skipTokens)
    }
}
