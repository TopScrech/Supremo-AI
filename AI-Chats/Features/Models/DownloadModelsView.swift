import SwiftUI

struct DownloadModelsView: View {
    @Environment(ChatAppModel.self) private var appModel

    var body: some View {
        List {
            Section("Install") {
                Text("Download a featured GGUF model below. When the first model finishes, it is assigned to the current chat automatically")
            }

            Section("Featured GGUF Models") {
                ForEach(appModel.downloadableModels) {
                    DownloadableModelRowView(model: $0)
                }
            }

            if !appModel.statusMessage.isEmpty {
                Section("Status") {
                    Text(appModel.statusMessage)
                }
            }
        }
        .navigationTitle("Downloads")
    }
}
