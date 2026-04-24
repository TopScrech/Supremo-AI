import SwiftUI

struct DownloadModelsView: View {
    @Environment(ChatAppModel.self) private var appModel
    
    var body: some View {
        List {
            Text("Download a featured GGUF model below. When the first model finishes, it is assigned to the current chat automatically")
            
            Section("Featured GGUF Models") {
                ForEach(appModel.downloadableModels) {
                    DownloadableModelRowView($0)
                }
            }
        }
        .navigationTitle("Downloads")
    }
}
