import SwiftUI

struct ShortcutsInfoView: View {
    var body: some View {
        List {
            Section("Available Actions") {
                Label("Ask local LLM", systemImage: "questionmark.bubble")
                Label("Summarize text", systemImage: "text.badge.checkmark")
            }
        }
    }
}
