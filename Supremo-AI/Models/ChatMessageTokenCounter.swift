struct ChatMessageTokenCounter {
    static func count(in text: String) -> Int {
        var count = 0
        var isInsideToken = false

        for character in text {
            if character.isWhitespace {
                isInsideToken = false
            } else if !isInsideToken {
                count += 1
                isInsideToken = true
            }
        }

        return count
    }
}
