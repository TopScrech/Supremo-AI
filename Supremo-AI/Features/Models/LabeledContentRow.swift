import ScrechKit

struct LabeledContentRow: View {
    private let title: String
    private let systemImage: String
    private let value: String
    
    init(_ title: String, systemImage: String, value: String) {
        self.title = title
        self.systemImage = systemImage
        self.value = value
    }
    
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
