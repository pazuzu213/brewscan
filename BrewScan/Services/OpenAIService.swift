import Foundation
import UIKit

struct PodIdentificationResult {
    let podName: String?
    let confidence: Double
    let line: String?
    let colorObserved: String
    let textObserved: String
    let notes: String
}

enum OpenAIError: LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case parsingError(String)
    case rateLimited
    case insufficientQuota
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please add your OpenAI API key in Config.swift."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .parsingError(let detail):
            return "Could not parse response: \(detail)"
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .insufficientQuota:
            return "Scanning is temporarily unavailable. Please contact support."
        case .serverError(let code):
            return "Server error (code \(code)). Please try again later."
        }
    }
}

class OpenAIService {
    static let shared = OpenAIService()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }

    func identifyPod(imageData: Data) async throws -> PodIdentificationResult {
        guard !Config.openAIKey.isEmpty else {
            throw OpenAIError.invalidAPIKey
        }
        return try await identifyPodWithRetry(imageData: imageData, attempt: 1)
    }

    // MARK: - Retry Logic

    private func identifyPodWithRetry(imageData: Data, attempt: Int) async throws -> PodIdentificationResult {
        let maxAttempts = 3
        let base64Image = imageData.base64EncodedString()

        let prompt = """
        You are a Nespresso capsule expert. Analyze this image of a Nespresso capsule. \
        Identify the exact pod name and line (Original or Vertuo). \
        Return JSON only: { "podName": string or null, "line": string or null, "confidence": number 0-1, \
        "colorObserved": string, "textObserved": string, "notes": string }
        """

        let requestBody: [String: Any] = [
            "model": Config.openAIModel,
            "max_tokens": 500,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "low"  // low = faster + fewer tokens, sufficient for pod ID
                            ]
                        ]
                    ]
                ]
            ]
        ]

        guard let url = URL(string: "\(Config.openAIBaseURL)/chat/completions") else {
            throw OpenAIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.openAIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            break
        case 401:
            throw OpenAIError.invalidAPIKey
        case 429:
            if isInsufficientQuotaResponse(data) {
                throw OpenAIError.insufficientQuota
            }
            guard attempt < maxAttempts else { throw OpenAIError.rateLimited }
            // Honour Retry-After header if present, otherwise exponential backoff
            let retryAfter: Double
            if let header = httpResponse.value(forHTTPHeaderField: "Retry-After"),
               let seconds = Double(header) {
                retryAfter = min(seconds, 10)
            } else {
                retryAfter = pow(2.0, Double(attempt))  // 2s, 4s, 8s
            }
            try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
            return try await identifyPodWithRetry(imageData: imageData, attempt: attempt + 1)
        case 500...599:
            guard attempt < maxAttempts else { throw OpenAIError.serverError(httpResponse.statusCode) }
            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
            return try await identifyPodWithRetry(imageData: imageData, attempt: attempt + 1)
        default:
            throw OpenAIError.serverError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }

        return try parseIdentificationResult(from: content)
    }

    private func isInsufficientQuotaResponse(_ data: Data) -> Bool {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any] else {
            return false
        }

        return error["code"] as? String == "insufficient_quota"
    }

    private func parseIdentificationResult(from content: String) throws -> PodIdentificationResult {
        // Extract JSON from the response (GPT sometimes wraps in markdown)
        var jsonString = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if jsonString.hasPrefix("```json") {
            jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
            jsonString = jsonString.replacingOccurrences(of: "```", with: "")
            jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if jsonString.hasPrefix("```") {
            jsonString = jsonString.replacingOccurrences(of: "```", with: "")
            jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let jsonData = jsonString.data(using: .utf8),
              let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw OpenAIError.parsingError("Could not parse JSON from response: \(content)")
        }

        let podName = parsed["podName"] as? String
        let confidence = parsed["confidence"] as? Double ?? 0.0
        let line = parsed["line"] as? String
        let colorObserved = parsed["colorObserved"] as? String ?? "Unknown"
        let textObserved = parsed["textObserved"] as? String ?? "Unknown"
        let notes = parsed["notes"] as? String ?? ""

        return PodIdentificationResult(
            podName: podName,
            confidence: confidence,
            line: line,
            colorObserved: colorObserved,
            textObserved: textObserved,
            notes: notes
        )
    }
}
