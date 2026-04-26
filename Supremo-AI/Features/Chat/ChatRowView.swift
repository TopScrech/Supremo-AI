import ScrechKit

struct ChatRowView: View {
    private let chat: ChatConfiguration
    
    init(_ chat: ChatConfiguration) {
        self.chat = chat
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(chat.title)
                .headline()
            
            Text(chat.modelName)
                .subheadline()
                .secondary()
            
            Text(chat.updatedAt, format: .relative(presentation: .numeric))
                .caption()
                .foregroundStyle(.tertiary)
        }
    }
}
