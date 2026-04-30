struct SamplingSettings: Codable, Equatable {
    var method = SamplingMethod.temperature
    var temperature = 0.9
    var topK = 40
    var topP = 0.95
    var tailFreeSampling = 1.0
    var typicalP = 1.0
    var repeatLastN = 64
    var repeatPenalty = 1.1
    var mirostatTau = 5.0
    var mirostatEta = 0.1
    var grammar = "None"
}
