import ScrechKit
import UniformTypeIdentifiers

struct DocumentsView: View {
    @Environment(ChatAppModel.self) private var appModel
    
    let chat: ChatConfiguration
    
    @State private var showNewDocument = false
    @State private var showImporter = false
    
    var body: some View {
        Section("Documents for RAG") {
            if chat.documents.isEmpty {
                ContentUnavailableView("No Documents", systemImage: "doc.text.magnifyingglass", description: Text("Add text documents to make RAG answers available"))
            } else {
                ForEach(chat.documents) { document in
                    RAGDocumentCard(document: document)
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                appModel.removeDocument(document, from: chat)
                            }
                        }
                }
            }
            
            Button("Add Text", systemImage: "plus") {
                showNewDocument = true
            }
            
            Button("Import File", systemImage: "doc.badge.plus") {
                showImporter = true
            }
        }
        .sheet($showNewDocument) {
            NavigationStack {
                NewDocumentView(chat: chat)
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.plainText, .text, .json]) { result in
            if let url = try? result.get(), let text = try? String(contentsOf: url, encoding: .utf8) {
                appModel.addDocument(title: url.deletingPathExtension().lastPathComponent, text: text, to: chat)
            }
        }
    }
}
