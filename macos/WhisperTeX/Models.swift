import Foundation
import SwiftUI

enum MathDelimiter: String, CaseIterable, Identifiable, Codable {
    case display = "display"   // $$...$$
    case inline = "inline"     // $...$
    case bracket = "bracket"   // \[...\]
    case raw = "raw"           // raw code

    var id: String { rawValue }

    var label: String {
        switch self {
        case .display: return "$$...$$ (Display)"
        case .inline: return "$...$ (Inline)"
        case .bracket: return "\\[...\\] (Block)"
        case .raw: return "Raw LaTeX"
        }
    }
}

enum LLMProvider: String, CaseIterable, Identifiable, Codable {
    case groq = "groq"
    case openai = "openai"
    case gemini = "gemini"
    case offline = "offline"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .groq: return "Groq (Llama 3.3 - Fast)"
        case .openai: return "OpenAI (GPT-4o-mini)"
        case .gemini: return "Google Gemini (2.0 Flash)"
        case .offline: return "Built-in / Offline Engine"
        }
    }
}

enum DictationState: Equatable {
    case idle
    case recording
    case transcribing
    case compiling
    case success(String)
    case error(String)

    var statusText: String {
        switch self {
        case .idle: return "Ready"
        case .recording: return "Listening to Math..."
        case .transcribing: return "Transcribing Audio..."
        case .compiling: return "Compiling LaTeX..."
        case .success: return "Compiled & Pasted!"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

struct MathPreset: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let spoken: String
    let expected: String
    let description: String
}
