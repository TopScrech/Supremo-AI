import ScrechKit

struct LabeledContentRow: View {
    let title: String
    let systemImage: String
    let value: String
    
    var body: some View {
        LabeledContent {
            Text(value)
                .monospacedDigit()
                .secondary()
        } label: {
            Label(title, systemImage: systemImage)
        }
    }
}
