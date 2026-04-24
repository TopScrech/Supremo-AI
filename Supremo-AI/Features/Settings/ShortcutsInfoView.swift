import SwiftUI

struct ShortcutsInfoView: View {
    var body: some View {
        List {
            Section("Available Actions") {
                Label("Ask a local chat", systemImage: "questionmark.bubble")
                Label("Summarize text with a selected chat", systemImage: "text.badge.checkmark")
                Label("Query RAG documents", systemImage: "doc.text.magnifyingglass")
            }
            
            Section("Runtime") {
                Text("Shortcut execution uses the same chat configuration, RAG documents, and model selection as the app")
                Text("Text chat uses the native llmfarm_core.swift engine")
            }
        }
        .navigationTitle("Shortcuts")
    }
}
