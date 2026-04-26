import SwiftUI
import ChitChat

struct ChatInputBar: View {
    @Binding var prompt: String
    let isGenerating: Bool
    let sendAction: () -> Void
    
    var body: some View {
        ChatComposer(prompt: $prompt, isResponding: .constant(isGenerating)) {
            sendAction()
        }
    }
}
