import ScrechKit

struct DownloadableModelRowView: View {
    @Environment(ChatAppModel.self) private var appModel
    let model: DownloadableModel

    var body: some View {
        let downloadState = appModel.downloadStates[model.fileName]

        VStack(alignment: .leading) {
            Text(model.familyName)
                .headline()
            Text(model.fileName)
                .secondary()
            HStack {
                Label(model.inference.label, systemImage: "cpu")
                Label(model.quantization, systemImage: "tag")
                Label(model.displaySize, systemImage: "externaldrive")
            }
            .caption()
            .foregroundStyle(.tertiary)

            if let downloadState, downloadState.isDownloading {
                ProgressView(value: downloadState.progress)
                Text(downloadState.statusText)
                    .caption()
                    .secondary()
            } else {
                HStack {
                    Button("Download", systemImage: "arrow.down.circle") {
                        Task {
                            await appModel.download(model)
                        }
                    }
                    .buttonStyle(.bordered)

                    if let downloadState, let errorMessage = downloadState.errorMessage {
                        Text(errorMessage)
                            .caption()
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .contextMenu {
            Button("Copy Download Link", systemImage: "link") {
                copyDownloadLink()
            }
        }
    }

    private func copyDownloadLink() {
        #if os(iOS) || os(visionOS)
        UIPasteboard.general.string = model.url.absoluteString
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(model.url.absoluteString, forType: .string)
        #endif

        appModel.statusMessage = "Copied download link"
    }
}
