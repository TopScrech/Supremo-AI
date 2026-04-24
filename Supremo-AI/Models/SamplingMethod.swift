import Foundation

enum SamplingMethod: String, Codable, CaseIterable, Identifiable {
    case temperature, greedy, mirostat, mirostatV2, grammar

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mirostatV2: "Mirostat v2"
        default: rawValue.capitalized
        }
    }
}
