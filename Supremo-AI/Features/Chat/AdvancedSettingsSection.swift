import ScrechKit

struct AdvancedSettingsSection: View {
    @Binding var chat: ChatConfiguration
    
    var body: some View {
        Section("Advanced") {
            LabeledContent("Created", value: chat.createdAt, format: .dateTime)
            LabeledContent("Updated", value: chat.updatedAt, format: .dateTime)
        }
    }
}
