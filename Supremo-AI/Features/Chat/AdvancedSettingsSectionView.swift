import ScrechKit

struct AdvancedSettingsSectionView: View {
    @Binding var chat: ChatConfiguration

    var body: some View {
        Section("Advanced") {
            Text(chat.id.uuidString)
                .caption()
                .textSelection(.enabled)

            LabeledContent("Created", value: chat.createdAt, format: .dateTime)
            LabeledContent("Updated", value: chat.updatedAt, format: .dateTime)
        }
    }
}
