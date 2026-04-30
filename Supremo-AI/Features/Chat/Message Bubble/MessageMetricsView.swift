import ScrechKit

struct MessageMetricsView: View {
    private let message: ChatMessage
    
    init(_ message: ChatMessage) {
        self.message = message
    }
    
    private var totalTokens: Int {
        ChatMessageTokenCounter.count(in: message.targetText ?? message.text)
    }
    
    var body: some View {
        Text("\(totalTokens) tokens")
            .caption()
            .secondary()
            .padding(.horizontal)
            .monospacedDigit()
    }
}
