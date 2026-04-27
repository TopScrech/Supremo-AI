import ScrechKit

struct MessageContentView: View {
    let message: ChatMessage
    let style: ChatStyle

    var body: some View {
        let parsedText = parsedMessageText

        VStack(alignment: .leading) {
            if let thought = parsedText.thought {
                MarkdownText(thought)
                    .font(.system(.footnote, design: .monospaced))
                    .secondary()
                    .textSelection(.enabled)
            }

            if style == .compact {
                MarkdownText(parsedText.answer)
                    .textSelection(.enabled)
            } else {
                MarkdownText(parsedText.answer)
                    .textSelection(.enabled)
                    .callout()
            }
        }
    }

    private var parsedMessageText: (thought: String?, answer: String) {
        guard message.role == .assistant else {
            return (nil, message.text)
        }

        if let thinkSegment = parsedThinkSegment(in: message.text) {
            return thinkSegment
        }

        let channelSegments = parsedChannelSegments(in: message.text)

        guard !channelSegments.isEmpty else {
            if let channelEnd = message.text.range(of: "<channel|>") {
                let thought = String(message.text[..<channelEnd.lowerBound])
                let answer = String(message.text[channelEnd.upperBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return (cleanedThoughtText(thought), answer)
            }

            return (nil, message.text)
        }

        let thought = channelSegments
            .filter { $0.name == "thought" }
            .map(\.text)
            .joined(separator: "\n\n")
        let answer = channelSegments
            .filter { $0.name != "thought" }
            .map(\.text)
            .joined(separator: "\n\n")

        if channelSegments.count == 1,
           channelSegments[0].name == "thought",
           let channelEnd = channelSegments[0].text.range(of: "<channel|>", options: .backwards) {
            let thought = String(channelSegments[0].text[..<channelEnd.lowerBound])
            let answer = String(channelSegments[0].text[channelEnd.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (cleanedThoughtText(thought), answer)
        }

        if answer.isEmpty {
            return (cleanedThoughtText(thought), "")
        }

        return (cleanedThoughtText(thought), answer)
    }

    private func parsedThinkSegment(in text: String) -> (thought: String?, answer: String)? {
        guard let openingRange = text.range(of: "<think>") else { return nil }

        let answerPrefix = String(text[..<openingRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let closingRange = text[openingRange.upperBound...].range(of: "</think>") else {
            let thought = String(text[openingRange.upperBound...])
            return (cleanedThoughtText(thought), answerPrefix)
        }

        let thought = String(text[openingRange.upperBound..<closingRange.lowerBound])
        let answerSuffix = String(text[closingRange.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let answer = [answerPrefix, answerSuffix]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

        return (cleanedThoughtText(thought), answer)
    }

    private func parsedChannelSegments(in text: String) -> [(name: String, text: String)] {
        let channelStartToken = "<|channel>"
        let channelBodyToken = "<channel|>"
        var segments: [(name: String, text: String)] = []
        var searchStart = text.startIndex

        while let channelStart = text[searchStart...].range(of: channelStartToken),
              let bodyStart = text[channelStart.upperBound...].range(of: channelBodyToken) {
            let rawName = String(text[channelStart.upperBound..<bodyStart.lowerBound])
            let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            let contentStart = bodyStart.upperBound
            let nextChannelStart = text[contentStart...].range(of: channelStartToken)?.lowerBound ?? text.endIndex
            let content = String(text[contentStart..<nextChannelStart])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !name.isEmpty || !content.isEmpty {
                segments.append((name, content))
            }

            searchStart = nextChannelStart

            if searchStart == text.endIndex {
                break
            }
        }

        return segments
    }

    private func cleanedThoughtText(_ text: String) -> String? {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanedText.isEmpty ? nil : cleanedText
    }
}
