import SwiftUI

struct ChatSettingsEditor: View {
    @Environment(ChatAppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var draft: ChatConfiguration
    @State private var section = ChatSettingsSection.basic
    
    init(_ chat: ChatConfiguration) {
        _draft = State(initialValue: chat)
    }
    
    var body: some View {
        TabView(selection: $section) {
            ForEach(ChatSettingsSection.allCases) { section in
                Tab(section.label, systemImage: section.systemImage, value: section) {
                    ChatSettingsSectionContent(section: section, chat: $draft)
                }
            }
        }
        .navigationTitle(section.label)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", systemImage: "checkmark") {
                    appModel.updateChat(draft)
                    dismiss()
                }
            }
        }
    }
}
