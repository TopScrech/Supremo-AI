import Foundation

struct RemoteFileSizeResolver {
    func sizeBytes(for url: URL) async throws -> Int {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<400).contains(httpResponse.statusCode),
              httpResponse.expectedContentLength > 0 else {
            throw URLError(.badServerResponse)
        }
        
        return Int(httpResponse.expectedContentLength)
    }
}
