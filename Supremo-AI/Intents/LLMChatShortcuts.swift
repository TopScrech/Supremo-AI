import AppIntents

struct LLMChatShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskLocalChatIntent(),
            phrases: [
                "Ask \(.applicationName)",
                "Ask local LLM with \(.applicationName)"
            ],
            shortTitle: "Ask LLM",
            systemImageName: "bubble.left.and.text.bubble.right"
        )
        
        AppShortcut(
            intent: SummarizeTextIntent(),
            phrases: [
                "Summarize with \(.applicationName)",
                "Summarize text using \(.applicationName)"
            ],
            shortTitle: "Summarize",
            systemImageName: "text.badge.checkmark"
        )
    }
}
