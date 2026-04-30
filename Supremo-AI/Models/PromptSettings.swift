struct PromptSettings: Codable, Equatable {
    var systemPrompt = "You are a helpful local assistant"
    var promptFormat = "[system](You are a helpful assistant)\n<|user|>{prompt}</|user|>\n<|assistant|>"
    var reversePrompt = ""
    var skipTokens = ""
}
