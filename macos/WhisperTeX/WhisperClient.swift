import Foundation

class WhisperClient {
    static let shared = WhisperClient()

    func validateKey(provider: LLMProvider, apiKey: String) async throws -> Bool {
        guard !apiKey.isEmpty else { return false }
        let endpoint: URL
        if provider == .groq {
            endpoint = URL(string: "https://api.groq.com/openai/v1/models")!
        } else if provider == .openai {
            endpoint = URL(string: "https://api.openai.com/v1/models")!
        } else {
            return true
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 7.0

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { return false }
        return httpResponse.statusCode == 200
    }

    func transcribe(fileURL: URL, provider: LLMProvider, apiKey: String) async throws -> String {
        let endpoint: URL
        let model: String
        let authHeader: String

        if provider == .groq {
            guard !apiKey.isEmpty else {
                throw NSError(domain: "WhisperTeX", code: 401, userInfo: [NSLocalizedDescriptionKey: "Groq API key required for transcription."])
            }
            endpoint = URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!
            model = "whisper-large-v3"
            authHeader = "Bearer \(apiKey)"
        } else {
            guard !apiKey.isEmpty else {
                throw NSError(domain: "WhisperTeX", code: 401, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key required for transcription."])
            }
            endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
            model = "whisper-1"
            authHeader = "Bearer \(apiKey)"
        }

        let audioData = try Data(contentsOf: fileURL)
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(model)\r\n".data(using: .utf8)!)

        // language field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("en\r\n".data(using: .utf8)!)

        // file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "WhisperTeX", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid network response from transcription service"])
        }

        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown HTTP \(httpResponse.statusCode)"
            throw NSError(domain: "WhisperTeX", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Whisper error: \(errorText)"])
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let text = json["text"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        throw NSError(domain: "WhisperTeX", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not parse transcription output"])
    }
}
