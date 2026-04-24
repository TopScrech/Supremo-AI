import SwiftUI

struct ModelFileRowView: View {
    @Environment(ChatAppModel.self) private var appModel
    let model: ModelFile

    var body: some View {
        VStack(alignment: .leading) {
            Text(model.displayName)
                .font(.headline)
            Text(model.fileName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Label(model.family.label, systemImage: "cpu")
                Label(model.quantization, systemImage: "tag")
                Label(model.sizeDescription, systemImage: "internaldrive")
                if model.isMultimodalProjector {
                    Label("Projector", systemImage: "photo")
                }
                if model.isPartialDownload == true {
                    Label("Partial download", systemImage: "hourglass")
                }
            }
            .font(.caption)
            .foregroundStyle(.tertiary)

            if let chat = appModel.selectedChat {
                HStack {
                    if model.isAvailableLocally {
                        Button("Use for Current Chat", systemImage: "checkmark.circle") {
                            appModel.assignModel(model, to: chat)
                        }
                        .buttonStyle(.bordered)
                    }

                    Button("Delete", systemImage: "trash", role: .destructive) {
                        appModel.deleteModel(model)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}
