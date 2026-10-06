import Foundation

class LatexCompiler {
    static let shared = LatexCompiler()

    let systemPrompt = """
    You are an expert mathematical typesetter and LaTeX compiler.
    Your task is to convert spoken mathematical English into clean, compilable, idiomatic LaTeX.
    
    Strict Rules:
    1. Output ONLY the compilable LaTeX equation. Do NOT include explanations, conversational filler, or markdown code blocks (e.g. do NOT wrap with ```latex).
    2. Output the formula with NO outer enclosing dollar signs (the client will apply the chosen delimiters).
    3. Understand mathematical context accurately:
       - "manifold M with metric tensor g sub mu nu" -> "\\mathcal{M}, \\quad g_{\\mu\\nu}"
       - "the integral from zero to infinity of x squared times e to the minus x dx equals two" -> "\\int_{0}^{\\infty} x^2 e^{-x} \\, dx = 2"
       - "capital G sub mu nu plus capital Lambda times g sub mu nu equals eight pi capital G over c to the fourth times capital T sub mu nu" -> "G_{\\mu\\nu} + \\Lambda g_{\\mu\\nu} = \\frac{8\\pi G}{c^4} T_{\\mu\\nu}"
       - "i h-bar partial derivative with respect to t of psi of x and t equals minus h-bar squared over two m second partial of psi with respect to x squared plus capital V of x times psi" -> "i\\hbar \\frac{\\partial \\psi(x,t)}{\\partial t} = -\\frac{\\hbar^2}{2m} \\frac{\\partial^2 \\psi}{\\partial x^2} + V(x)\\psi"
       - "bra psi H-hat ket psi" -> "\\langle \\psi | \\hat{H} | \\psi \\rangle"
       - Greek letters: alpha -> \\alpha, beta -> \\beta, mu -> \\mu, nu -> \\nu, Lambda -> \\Lambda, etc.
       - Vectors: "vector v" -> "\\mathbf{v}".
       - Differentials: "\\, dx", "\\, dt".
    """

    func compile(spoken: String, provider: LLMProvider, apiKey: String, delimiter: MathDelimiter) async throws -> (raw: String, formatted: String) {
        let raw: String

        if provider == .offline || apiKey.isEmpty {
            raw = offlineFallback(spoken: spoken)
        } else if provider == .groq {
            raw = try await callGroq(apiKey: apiKey, spoken: spoken)
        } else if provider == .openai {
            raw = try await callOpenAICompatible(
                url: URL(string: "https://api.openai.com/v1/chat/completions")!,
                model: "gpt-4o-mini",
                apiKey: apiKey,
                spoken: spoken
            )
        } else if provider == .gemini {
            raw = try await callGemini(apiKey: apiKey, spoken: spoken)
        } else {
            raw = offlineFallback(spoken: spoken)
        }

        let formatted = applyDelimiter(raw: raw, delimiter: delimiter)
        return (raw, formatted)
    }

    private func cleanLatex(_ text: String) -> String {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("```latex") {
            s = String(s.dropFirst(8))
        } else if s.hasPrefix("```") {
            s = String(s.dropFirst(3))
        }
        if s.hasSuffix("```") {
            s = String(s.dropLast(3))
        }
        s = s.trimmingCharacters(in: .whitespacesAndNewlines)

        if s.hasPrefix("$$") && s.hasSuffix("$$") && s.count >= 4 {
            s = String(s.dropFirst(2).dropLast(2))
        } else if s.hasPrefix("$") && s.hasSuffix("$") && s.count >= 2 {
            s = String(s.dropFirst(1).dropLast(1))
        } else if s.hasPrefix("\\[") && s.hasSuffix("\\]") && s.count >= 4 {
            s = String(s.dropFirst(2).dropLast(2))
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func applyDelimiter(raw: String, delimiter: MathDelimiter) -> String {
        let clean = cleanLatex(raw)
        switch delimiter {
        case .display:
            return "$$\n\(clean)\n$$"
        case .inline:
            return "$\(clean)$"
        case .bracket:
            return "\\[\n\(clean)\n\\]"
        case .raw:
            return clean
        }
    }

    private func callOpenAICompatible(url: URL, model: String, apiKey: String, spoken: String) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": spoken]
            ],
            "temperature": 0.1,
            "max_tokens": 500
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let err = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "WhisperTeX", code: 500, userInfo: [NSLocalizedDescriptionKey: "LLM error: \(err)"])
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return cleanLatex(content)
        }

        throw NSError(domain: "WhisperTeX", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse LLM response"])
    }

    private func callGroq(apiKey: String, spoken: String) async throws -> String {
        let models = [
            "llama-3.1-8b-instant",
            "openai/gpt-oss-20b",
            "llama-3.3-70b-versatile",
            "llama-3.1-70b-versatile"
        ]

        var lastError: Error?
        for model in models {
            do {
                return try await callOpenAICompatible(
                    url: URL(string: "https://api.groq.com/openai/v1/chat/completions")!,
                    model: model,
                    apiKey: apiKey,
                    spoken: spoken
                )
            } catch {
                lastError = error
                let errString = error.localizedDescription.lowercased()
                if errString.contains("model_not_found") || errString.contains("does not exist") || errString.contains("do not have access") {
                    // Try next model fallback
                    continue
                } else {
                    throw error
                }
            }
        }

        if let err = lastError {
            throw err
        }
        return offlineFallback(spoken: spoken)
    }

    private func callGemini(apiKey: String, spoken: String) async throws -> String {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "contents": [
                ["parts": [["text": "\(systemPrompt)\n\nSpoken mathematics:\n\"\(spoken)\""]]]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let err = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "WhisperTeX", code: 500, userInfo: [NSLocalizedDescriptionKey: "Gemini error: \(err)"])
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]],
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            return cleanLatex(text)
        }

        throw NSError(domain: "WhisperTeX", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Gemini response"])
    }

    private func offlineFallback(spoken: String) -> String {
        let lower = spoken.lowercased()
        if lower.contains("manifold") && lower.contains("metric tensor") {
            return "\\mathcal{M}, \\quad g_{\\mu\\nu}"
        }
        if lower.contains("integral") && lower.contains("zero to infinity") && lower.contains("minus x") {
            return "\\int_{0}^{\\infty} x^2 e^{-x} \\, dx = 2"
        }
        if lower.contains("capital g sub mu nu") || (lower.contains("einstein") && lower.contains("lambda")) {
            return "G_{\\mu\\nu} + \\Lambda g_{\\mu\\nu} = \\frac{8\\pi G}{c^4} T_{\\mu\\nu}"
        }
        if lower.contains("schrodinger") || (lower.contains("h-bar") && lower.contains("psi")) {
            return "i\\hbar \\frac{\\partial \\psi(x,t)}{\\partial t} = -\\frac{\\hbar^2}{2m} \\frac{\\partial^2 \\psi}{\\partial x^2} + V(x)\\psi"
        }
        if lower.contains("bra psi") && lower.contains("ket psi") {
            return "\\langle \\psi | \\hat{H} | \\psi \\rangle = \\int \\psi^*(x) \\hat{H} \\psi(x) \\, dx"
        }
        if lower.contains("gaussian") || (lower.contains("minus infinity to plus infinity") && lower.contains("minus x squared")) {
            return "\\int_{-\\infty}^{\\infty} e^{-x^2} \\, dx = \\sqrt{\\pi}"
        }
        if lower.contains("cauchy") || lower.contains("inner product of u and v") {
            return "|\\langle u, v \\rangle|^2 \\le \\langle u, u \\rangle \\cdot \\langle v, v \\rangle"
        }

        // Generic transforms
        var res = spoken
        let greek = [
            "alpha": "\\alpha", "beta": "\\beta", "gamma": "\\gamma", "delta": "\\delta",
            "lambda": "\\lambda", "mu": "\\mu", "nu": "\\nu", "pi": "\\pi",
            "sigma": "\\sigma", "theta": "\\theta", "omega": "\\omega"
        ]
        for (name, sym) in greek {
            res = res.replacingOccurrences(of: "\\b\(name)\\b", with: sym, options: .regularExpression)
        }
        res = res.replacingOccurrences(of: " squared", with: "^2")
        res = res.replacingOccurrences(of: " cubed", with: "^3")
        res = res.replacingOccurrences(of: " equals ", with: " = ")
        res = res.replacingOccurrences(of: " plus ", with: " + ")
        res = res.replacingOccurrences(of: " minus ", with: " - ")
        return res
    }
}
