import ScrechKit

struct MessageMetricsView: View {
    let message: ChatMessage
    
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
