import ScrechKit

struct RAGDocumentCard: View {
    private let document: RAGDocument
    
    init(_ document: RAGDocument) {
        self.document = document
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(document.title)
                .headline()
            
            Text(document.text)
                .lineLimit(2)
                .secondary()
            
            Text(document.importedAt, format: .dateTime)
                .caption()
                .foregroundStyle(.tertiary)
        }
    }
}
