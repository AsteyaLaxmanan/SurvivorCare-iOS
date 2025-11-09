//
//  OllamaConfig.swift
//  SurvivorshipCareSwift
//
//  Created by Asteya Laxmanan on 11/8/25.
//


// OllamaClient.swift
import Foundation

struct OllamaConfig {
    var baseURL: URL
    var model: String
}

enum OllamaError: Error, LocalizedError {
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from Ollama."
        case .server(let msg): return msg
        }
    }
}

final class OllamaClient {
    let config: OllamaConfig
    init(config: OllamaConfig) { self.config = config }

    /// Posts a combined JSON file to /api/chat with a custom system prompt and optional extra RAG text.
    func generateReport(for combinedJSON: URL,
                        systemPrompt: String,
                        ragSnippets: String? = nil) async throws -> String {

        let jsonData = try Data(contentsOf: combinedJSON)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw OllamaError.server("Could not read combined JSON as UTF-8.")
        }

        var userContent = """
        Here is today's combined JSON from the BioTwin app (physical + cognitive):

        ```json
        \(jsonString)
        ```
        """

        if let rag = ragSnippets, !rag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userContent += """

            Reference snippets (RAG), index-numbered for citation use:
            \(rag)
            """
        }

        let body: [String: Any] = [
            "model": config.model,
            "stream": false,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user",   "content": userContent]
            ]
        ]

        var req = URLRequest(url: config.baseURL.appendingPathComponent("/api/chat"))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw OllamaError.invalidResponse
        }

        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let err = obj?["error"] as? String { throw OllamaError.server(err) }
        if let msg = (obj?["message"] as? [String: Any])?["content"] as? String {
            return msg
        }
        throw OllamaError.invalidResponse
    }
}
