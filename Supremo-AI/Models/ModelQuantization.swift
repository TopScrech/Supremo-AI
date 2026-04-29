import Foundation

enum ModelQuantization {
    static func value(from fileName: String, fallback: String = "GGUF") -> String {
        let name = URL(filePath: fileName).deletingPathExtension().lastPathComponent
        let separators: Set<Character> = ["-", "_", "."]
        let scalars = Array(name)
        
        for index in scalars.indices.reversed() {
            guard separators.contains(scalars[index]) else { continue }
            
            let suffixStart = scalars.index(after: index)
            let suffix = String(scalars[suffixStart...])
            
            if isQuantizationSuffix(suffix) {
                return suffix.uppercased()
            }
        }
        
        return fallback
    }
    
    private static func isQuantizationSuffix(_ value: String) -> Bool {
        let lowercasedValue = value.lowercased()
        
        return lowercasedValue == "f16" ||
        lowercasedValue == "bf16" ||
        lowercasedValue.hasPrefix("q") ||
        lowercasedValue.hasPrefix("iq")
    }
}
