// Sources/Swit/Ollama/OllamaModel.swift

import Foundation

struct OllamaModel: Decodable, Equatable {
    let name: String
}

struct OllamaModelList: Decodable, Equatable {
    let models: [OllamaModel]
}
