// src/Swit/Ollama/OllamaChatResult.swift

import Foundation

struct OllamaChatResult: Decodable {
    struct Message: Decodable {
        let content: String
    }

    let message: Message?
    let totalDuration: Int64?
    let loadDuration: Int64?
    let promptEvalCount: Int?
    let evalCount: Int?
    let evalDuration: Int64?
    let doneReason: String?

    var content: String {
        message?.content
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var totalDurationSeconds: Double? {
        seconds(from: totalDuration)
    }

    var loadDurationSeconds: Double? {
        seconds(from: loadDuration)
    }

    var outputDurationSeconds: Double? {
        seconds(from: evalDuration)
    }

    private enum CodingKeys: String, CodingKey {
        case message
        case totalDuration = "total_duration"
        case loadDuration = "load_duration"
        case promptEvalCount = "prompt_eval_count"
        case evalCount = "eval_count"
        case evalDuration = "eval_duration"
        case doneReason = "done_reason"
    }

    private func seconds(from nanoseconds: Int64?) -> Double? {
        guard let nanoseconds, nanoseconds >= 0 else {
            return nil
        }

        return Double(nanoseconds) / 1_000_000_000
    }
}
