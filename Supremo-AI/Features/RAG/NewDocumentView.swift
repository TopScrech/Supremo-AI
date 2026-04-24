import SwiftUI

struct NewDocumentView: View {
    @Environment(ChatAppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var text = ""
    let chat: ChatConfiguration

    var body: some View {
        Form {
            Section("Document") {
                TextField("Title", text: $title)
                TextField("Text", text: $text, axis: .vertical)
                    .lineLimit(6...16)
            }
        }
        .navigationTitle("Add Document")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add", systemImage: "checkmark") {
                    appModel.addDocument(title: title, text: text, to: chat)
                    dismiss()
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
