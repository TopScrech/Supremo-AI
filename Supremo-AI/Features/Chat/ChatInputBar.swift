import SwiftUI

struct ChatInputBar: View {
    @Binding var prompt: String
    @Binding var useRAG: Bool
    let isGenerating: Bool
    let sendAction: () -> Void

    var body: some View {
        VStack {
            HStack {
                Toggle("RAG", isOn: $useRAG)
                    .toggleStyle(.button)

                TextField("Message", text: $prompt, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)

                Button("Send", systemImage: "paperplane.fill", action: sendAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
            }

            if isGenerating {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }
}
