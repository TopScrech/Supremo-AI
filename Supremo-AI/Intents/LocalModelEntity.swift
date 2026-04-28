import AppIntents
import Foundation

struct LocalModelEntity: AppEntity {
    nonisolated static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Local Model")
    nonisolated static let defaultQuery = LocalModelQuery()
    
    let id: UUID
    let displayName: String
    let fileName: String
    let quantization: String
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(displayName)",
            subtitle: "\(quantization) - \(fileName)"
        )
    }
    
    init(model: ModelFile) {
        id = model.id
        displayName = model.displayName
        fileName = model.fileName
        quantization = model.quantization
    }
}
