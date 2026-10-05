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

let SAMPLE_PRESETS: [MathPreset] = [
    MathPreset(
        title: "Gamma Function Integral",
        category: "Calculus",
        spoken: "The integral from zero to infinity of x squared times e to the minus x dx equals two",
        expected: "\\int_{0}^{\\infty} x^2 e^{-x} \\, dx = 2",
        description: "Definite bounds, exponential decay, powers, and differential."
    ),
    MathPreset(
        title: "Manifold Metric Tensor",
        category: "Differential Geometry",
        spoken: "manifold M with metric tensor g sub mu nu",
        expected: "\\mathcal{M}, \\quad g_{\\mu\\nu}",
        description: "Calligraphic manifold symbol and Greek covariant tensor indices."
    ),
    MathPreset(
        title: "Einstein Field Equations",
        category: "General Relativity",
        spoken: "capital G sub mu nu plus capital Lambda times g sub mu nu equals eight pi capital G over c to the fourth times capital T sub mu nu",
        expected: "G_{\\mu\\nu} + \\Lambda g_{\\mu\\nu} = \\frac{8\\pi G}{c^4} T_{\\mu\\nu}",
        description: "Relativity field equation with cosmological constant and energy-momentum tensor."
    ),
    MathPreset(
        title: "Time-Dependent Schrödinger Equation",
        category: "Quantum Mechanics",
        spoken: "i h-bar partial derivative with respect to t of psi of x and t equals minus h-bar squared over two m second partial of psi with respect to x squared plus capital V of x times psi",
        expected: "i\\hbar \\frac{\\partial \\psi(x,t)}{\\partial t} = -\\frac{\\hbar^2}{2m} \\frac{\\partial^2 \\psi}{\\partial x^2} + V(x)\\psi",
        description: "Reduced Planck constant, partial derivatives, and wave function."
    ),
    MathPreset(
        title: "Dirac Bra-Ket & Hamiltonian",
        category: "Quantum Mechanics",
        spoken: "bra psi H-hat ket psi equals integral of psi star of x H-hat psi of x dx",
        expected: "\\langle \\psi | \\hat{H} | \\psi \\rangle = \\int \\psi^*(x) \\hat{H} \\psi(x) \\, dx",
        description: "Bra-ket notation, operator hat, complex conjugate."
    ),
    MathPreset(
        title: "Gaussian Integral",
        category: "Calculus",
        spoken: "integral from minus infinity to plus infinity of e to the minus x squared dx equals square root of pi",
        expected: "\\int_{-\\infty}^{\\infty} e^{-x^2} \\, dx = \\sqrt{\\pi}",
        description: "Symmetric infinite limits with exponential squared."
    )
]
