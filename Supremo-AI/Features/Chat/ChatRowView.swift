import ScrechKit

struct ChatRowView: View {
    let chat: ChatConfiguration
    
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
