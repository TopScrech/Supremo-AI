import Foundation

struct RAGIndexer {
    func rankedContext(for query: String, documents: [RAGDocument], maxCount: Int) -> [RAGDocument] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return [] }

        return documents
            .map { document in
                (document, score(document: document, query: normalizedQuery))
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(maxCount)
            .map(\.0)
    }

    private func score(document: RAGDocument, query: String) -> Int {
        let words = query
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .filter { !$0.isEmpty }

        return words.reduce(0) { result, word in
            let titleScore = document.title.localizedStandardContains(word) ? 3 : 0
            let bodyScore = document.text.localizedStandardContains(word) ? 1 : 0
            return result + titleScore + bodyScore
        }
    }
}
