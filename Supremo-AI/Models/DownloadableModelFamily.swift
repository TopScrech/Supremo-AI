struct DownloadableModelFamily: Identifiable {
    var id: String { name }
    var name: String
    var models: [DownloadableModel]
}
