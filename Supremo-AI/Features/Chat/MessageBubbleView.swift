import ScrechKit

struct MessageBubbleView: View {
    let message: ChatMessage
    let style: ChatStyle
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: .leading) {
                Text(message.role.label)
                    .caption()
                    .secondary()
                if style == .compact {
                    Text(message.text)
                        .textSelection(.enabled)
                } else {
                    Text(message.text)
                        .textSelection(.enabled)
                        .callout()
                }
            }
            .padding()
            .background(backgroundStyle)
            .clipShape(.rect(cornerRadius: 8))
            
            if message.role != .user {
                Spacer()
            }
        }
    }
    
    private var backgroundStyle: some ShapeStyle {
        switch message.role {
        case .user: Color.blue.opacity(0.16)
        case .assistant: Color.green.opacity(0.14)
        case .system: Color.gray.opacity(0.14)
        case .rag: Color.orange.opacity(0.14)
        }
    }
}
