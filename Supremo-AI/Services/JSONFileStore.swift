import Foundation

struct JSONFileStore {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    let rootURL: URL
    
    init(rootURL: URL = URL.documentsDirectory.appending(path: "LLMChat")) {
        self.rootURL = rootURL
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    func load<Value: Decodable>(_ type: Value.Type, from fileName: String) throws -> Value {
        let url = rootURL.appending(path: fileName)
        let data = try Data(contentsOf: url)
        return try decoder.decode(type, from: data)
    }
    
    func save<Value: Encodable>(_ value: Value, to fileName: String) throws {
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        let url = rootURL.appending(path: fileName)
        let data = try encoder.encode(value)
        try data.write(to: url, options: .atomic)
    }
    
    func ensureDirectories() throws {
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: modelsURL, withIntermediateDirectories: true)
    }
    
    var modelsURL: URL {
        rootURL.appending(path: "Models")
    }
}
