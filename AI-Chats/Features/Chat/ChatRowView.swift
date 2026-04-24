import SwiftUI

struct ChatRowView: View {
    let chat: ChatConfiguration

    var body: some View {
        VStack(alignment: .leading) {
            Text(chat.title)
                .font(.headline)
            Text(chat.modelName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(chat.updatedAt, format: .relative(presentation: .numeric))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
