// Sources/Swit/Ollama/OllamaClient.swift

import Foundation

struct OllamaClient {
    let host: URL
    let model: String
    let temperature: Double
    let contextWindow: Int
    let keepAlive: String

    private let session: URLSession

    init(host: String,
         model: String,
         temperature: Double = AppConfiguration.defaultTemperature,
         contextWindow: Int = AppConfiguration.defaultContextWindow,
         keepAlive: String = AppConfiguration.defaultKeepAlive) throws
    {
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = URL(string: trimmedHost),
             let scheme = url.scheme?.lowercased(),
             ["http", "https"].contains(scheme),
             url.host != nil
        else {
            throw SwitError.invalidHost(host)
        }

        guard ConfigurationValidator.isValid(temperature: temperature) else {
            throw SwitError.invalidTemperature(temperature)
        }

        guard ConfigurationValidator.isValid(contextWindow: contextWindow) else {
            throw SwitError.invalidContextWindow(contextWindow)
        }

        guard ConfigurationValidator.isValid(keepAlive: keepAlive) else {
            throw SwitError.invalidKeepAlive(keepAlive)
        }

        self.host = url
        self.model = model
        self.temperature = temperature
        self.contextWindow = contextWindow
        self.keepAlive = keepAlive

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 120
        configuration.timeoutIntervalForResource = 180
        self.session = URLSession(configuration: configuration)
    }

    func version() async throws -> String {
        let endpoint = endpointURL(path: "api/version")
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: endpoint)
        } catch {
            throw SwitError.ollamaUnreachable(host.absoluteString)
        }

        if let http = response as? HTTPURLResponse,
            !(200...299).contains(http.statusCode)
        {
            let body = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw mapOllamaError(body)
        }

        let decoded: OllamaVersionResponse

        do {
            decoded = try JSONDecoder().decode(OllamaVersionResponse.self, from: data)
        } catch {
            throw SwitError.ollamaFailed("Could not read Ollama version.")
        }

        let version = decoded.version.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !version.isEmpty else {
            throw SwitError.ollamaFailed("Ollama returned an empty version.")
        }

        return version
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
                options: .init(
                    temperature: temperature,
                    numContext: contextWindow
                ),
                keepAlive: keepAlive
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
            throw SwitError.ollamaFailed("Answer could not be read.")
        }

        let content = decoded.message?.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if content.isEmpty {
            throw SwitError.ollamaFailed("Empty answer from model '\(model)'.")
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
    let keepAlive: String

    enum CodingKeys: String, CodingKey {
        case model
        case stream
        case messages
        case options
        case keepAlive = "keep_alive"
    }

    struct Options: Encodable {
        let temperature: Double
        let numContext: Int

        enum CodingKeys: String, CodingKey {
            case temperature
            case numContext = "num_ctx"
        }
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
private struct OllamaVersionResponse: Decodable {
    let version: String
}
