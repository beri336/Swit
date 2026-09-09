// Sources/Gith/Ollama/OllamaClient.swift

import Foundation

struct OllamaClient {
    let host: URL
    let model: String
    private let session: URLSession

    init(host: String, model: String) throws {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme,
            scheme == "http" || scheme == "https"
        else {
            throw SwitError.invalidHost(host)
        }
        self.host = url
        self.model = model

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        self.session = URLSession(configuration: config)
    }

    func listModels() async throws -> [OllamaModel] {
        let endpoint = tagsURL()
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: endpoint)
        } catch {
            throw SwitError.ollamaUnreachable(host.absoluteString)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw mapOllamaError(body)
        }

        let decoded: OllamaModelList

        do {
            decoded = try JSONDecoder().decode(OllamaModelList.self, from: data)
        } catch {
            throw SwitError.ollamaFailed("Could not read model list.")
        }

        let models = decoded.models.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }

        guard !model.isEmpty else {
            throw SwitError.noOllamaModels(host.absoluteString)
        }

        return models
    }

    func chat(system: String, user: String) async throws -> String {
        let endpoint = chatURL()
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            ChatRequest(
                model: model,
                stream: false,
                messages: [
                    .init(role: "system", content: system),
                    .init(role: "user", content: user),
                ],
                options: .init(temperature: 0.2)
            )
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw SwitError.ollamaUnreachable(host.absoluteString)
        }

        if let errorPayload = try? JSONDecoder().decode(OllamaErrorPayload.self, from: data),
            let message = errorPayload.error, !message.isEmpty
        {
            throw mapOllamaError(message)
        }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw mapOllamaError(body)
        }

        let decoded: ChatResponse
        do {
            decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch {
            throw SwitError.ollamaFailed("Antwort konnte nicht gelesen werden.")
        }

        let content = decoded.message?.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if content.isEmpty {
            throw SwitError.ollamaFailed("Leere Antwort vom Modell '\(model)'.")
        }
        return content
    }

    private func chatURL() -> URL {
        endpointURL(path: "api/chat")
    }

    private func tagsURL() -> URL {
        endpointURL(path: "api/tags")
    }

    private func endpointURL(path: String) -> URL {
        var base = host.absoluteString

        while base.hasSuffix("/") {
            base.removeLast()
        }

        return URL(string: "\(base)/\(path)") ?? host.appendingPathComponent(path)
    }

    private func mapOllamaError(_ message: String) -> SwitError {
        let lower = message.lowercased()
        if lower.contains("not found") || lower.contains("model") && lower.contains("try pulling") {
            return .ollamaModelMissing(model)
        }
        return .ollamaFailed(message)
    }
}
private struct ChatRequest: Encodable {
    let model: String
    let stream: Bool
    let messages: [ChatMessage]
    let options: Options

    struct Options: Encodable {
        let temperature: Double
    }
}
private struct ChatMessage: Codable {
    let role: String
    let content: String
}
private struct ChatResponse: Decodable {
    let message: ChatMessage?
}
private struct OllamaErrorPayload: Decodable {
    let error: String?
}
