import ScrechKit

struct MessageBubbleView: View {
    @AppStorage(AppStorageKey.debugMode) private var debugMode = false
    
    let message: ChatMessage
    let style: ChatStyle
    let showTokenCount: Bool
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: bubbleAlignment) {
                VStack(alignment: .leading) {
                    Text(message.role.label)
                        .caption()
                        .secondary()
                    
                    MessageContentView(message: message, style: style)
                }
                .padding()
                .background(backgroundStyle)
                .clipShape(.rect(cornerRadius: 8))
                
                if debugMode {
                    tokenCountLabel
                }
            }
            
            if message.role != .user {
                Spacer()
            }
        }
    }
    
    private var bubbleAlignment: HorizontalAlignment {
        message.role == .user ? .trailing : .leading
    }
    
    @ViewBuilder
    private var tokenCountLabel: some View {
        if showTokenCount {
            MessageMetricsView(message: message)
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
