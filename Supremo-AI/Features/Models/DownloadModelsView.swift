import SwiftUI

struct DownloadModelsView: View {
    @Environment(ChatAppModel.self) private var appModel
    
    var body: some View {
        List {
            Text("When the first model finishes, it is assigned to the current chat automatically")
            
            Section("Featured") {
                ForEach(appModel.downloadableModels) {
                    DownloadableModelCard($0)
                }
            }
        }
        .navigationTitle("Downloads")
    }
}
