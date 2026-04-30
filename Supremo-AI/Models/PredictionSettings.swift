struct PredictionSettings: Codable, Equatable {
    var contextLength = 2048
    var batchSize = 512
    var threadCount = 0
    var maxTokens = 512
    var restoreContextState = true
    var useMetal = true
    var useClipMetal = true
    var mmap = true
    var mlock = false
    var flashAttention = false
    var addBosToken = false
    var addEosToken = false
    var parseSpecialTokens = true
}
