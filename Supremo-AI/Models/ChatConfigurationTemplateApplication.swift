extension ChatConfiguration {
    mutating func applyTemplate(_ template: ChatSettingsTemplate) {
        settings.modelSettingsTemplate = template.name
        settings.inference = template.inference
        settings.prediction.contextLength = template.contextLength
        settings.prediction.batchSize = template.batchSize
        settings.prediction.useMetal = template.useMetal
        settings.sampling.temperature = template.temperature
        settings.sampling.topK = template.topK
        settings.sampling.topP = template.topP
        settings.prompt.promptFormat = template.promptFormat
    }
    
    mutating func applyAutomaticTemplate(for model: ModelFile) {
        if let template = ChatSettingsTemplate.automaticTemplate(for: model) {
            applyTemplate(template)
        } else {
            settings.inference = model.family
        }
    }
}
