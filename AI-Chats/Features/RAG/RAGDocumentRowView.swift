import SwiftUI

struct RAGDocumentRowView: View {
    let document: RAGDocument

    var body: some View {
        VStack(alignment: .leading) {
            Text(document.title)
                .font(.headline)
            Text(document.text)
                .lineLimit(2)
                .foregroundStyle(.secondary)
            Text(document.importedAt, format: .dateTime)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
