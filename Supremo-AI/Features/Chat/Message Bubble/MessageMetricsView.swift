import ScrechKit

struct MessageMetricsView: View {
    let message: ChatMessage
    
    private var totalTokens: Int {
        ChatMessageTokenCounter.count(in: message.targetText ?? message.text)
    }
    
    private var tokensPerSecond: String? {
        message.tokensPerSecond?.formatted(.number.precision(.fractionLength(1)))
    }
    
    private var ttft: String? {
        message.timeToFirstToken?.formatted(.number.precision(.fractionLength(2)))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text("\(totalTokens) tokens")
            
            Text(" • ")
            
            if let tokensPerSecond {
                Text("\(tokensPerSecond) tok/s")
            }
            
            Text(" • ")
            
            if let ttft {
                Text("\(ttft)s TTFT")
            }
        }
        .caption()
        .secondary()
        .padding(.horizontal)
        .monospacedDigit()
    }
}
