import Foundation
import SwiftUI
import AppKit

@MainActor
class AppViewModel: ObservableObject {
    @Published var state: DictationState = .idle
    @Published var spokenText: String = "The integral from zero to infinity of x squared times e to the minus x dx equals two"
    @Published var rawLatex: String = "\\int_{0}^{\\infty} x^2 e^{-x} \\, dx = 2"
    @Published var formattedLatex: String = "$$\n\\int_{0}^{\\infty} x^2 e^{-x} \\, dx = 2\n$$"
    @Published var delimiter: MathDelimiter = .display
    @Published var provider: LLMProvider = .groq
    @Published var autoPaste: Bool = true
    @Published var copied: Bool = false
    @Published var showSettings: Bool = false

    @Published var isTestingGroqKey: Bool = false
    @Published var groqKeyStatus: String? = nil
    @Published var isTestingOpenAIKey: Bool = false
    @Published var openaiKeyStatus: String? = nil

    @AppStorage("groq_api_key") var groqApiKey: String = ""
    @AppStorage("openai_api_key") var openaiApiKey: String = ""
    @AppStorage("gemini_api_key") var geminiApiKey: String = ""

    let recorder = AudioRecorder()

    init() {
        if groqApiKey.isEmpty, let key = ProcessInfo.processInfo.environment["GROQ_API_KEY"] {
            groqApiKey = key
        }
        if openaiApiKey.isEmpty, let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            openaiApiKey = key
        }
        if geminiApiKey.isEmpty, let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            geminiApiKey = key
        }
    }

    func currentApiKey() -> String {
        switch provider {
        case .groq: return groqApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        case .openai: return openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        case .gemini: return geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        case .offline: return ""
        }
    }

    func toggleRecording() {
        if state == .recording {
            stopRecordingAndProcess()
        } else if state == .idle || (state != .transcribing && state != .compiling) {
            startRecording()
        }
    }

    func startRecording() {
        do {
            state = .recording
            _ = try recorder.start()
        } catch {
            state = .error("Record failed: \(error.localizedDescription)")
        }
    }

    func stopRecordingAndProcess() {
        state = .transcribing
        Task {
            do {
                let audioURL = try recorder.stop()
                let apiKey = currentApiKey()

                // Validate API Key before proceeding
                if provider != .offline && apiKey.isEmpty {
                    throw NSError(
                        domain: "WhisperTeX",
                        code: 401,
                        userInfo: [NSLocalizedDescriptionKey: "No API key configured for \(provider.label). Please enter or paste your API key in Settings / Permissions."]
                    )
                }

                let transcript: String
                if provider == .offline {
                    transcript = spokenText.isEmpty ? "The integral from zero to infinity of x squared times e to the minus x dx equals two" : spokenText
                } else {
                    transcript = try await WhisperClient.shared.transcribe(fileURL: audioURL, provider: provider, apiKey: apiKey)
                }

                guard !transcript.isEmpty else {
                    throw NSError(domain: "WhisperTeX", code: 400, userInfo: [NSLocalizedDescriptionKey: "No spoken speech detected in audio."])
                }

                // Immediately update the recognized speech so user sees what it heard
                await MainActor.run {
                    self.spokenText = transcript
                    self.state = .compiling
                }

                // Compile into LaTeX
                let result = try await LatexCompiler.shared.compile(
                    spoken: transcript,
                    provider: provider,
                    apiKey: apiKey,
                    delimiter: delimiter
                )

                await MainActor.run {
                    self.rawLatex = result.raw
                    self.formattedLatex = result.formatted
                    self.state = .success(result.formatted)

                    PasteboardHelper.shared.copyToClipboard(result.formatted)
                    self.copied = true

                    if self.autoPaste {
                        PasteboardHelper.shared.autoPaste()
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.copied = false
                        if self.state == .success(result.formatted) {
                            self.state = .idle
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.state = .error(error.localizedDescription)
                }
            }
            self.recorder.cleanup()
        }
    }

    func compileCustomSpokenText(_ text: String? = nil) {
        let input = (text ?? spokenText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        state = .compiling
        Task {
            do {
                let apiKey = currentApiKey()
                let result = try await LatexCompiler.shared.compile(
                    spoken: input,
                    provider: provider,
                    apiKey: apiKey,
                    delimiter: delimiter
                )
                await MainActor.run {
                    self.rawLatex = result.raw
                    self.formattedLatex = result.formatted
                    self.state = .success(result.formatted)
                    PasteboardHelper.shared.copyToClipboard(result.formatted)
                    self.copied = true

                    if self.autoPaste {
                        PasteboardHelper.shared.autoPaste()
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.copied = false
                        if self.state == .success(result.formatted) {
                            self.state = .idle
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    func updateDelimiter(_ newDelimiter: MathDelimiter) {
        delimiter = newDelimiter
        formattedLatex = LatexCompiler.shared.applyDelimiter(raw: rawLatex, delimiter: newDelimiter)
    }

    func pasteFromClipboard(for target: String) {
        guard let text = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        switch target {
        case "groq":
            groqApiKey = text
            groqKeyStatus = "Pasted from clipboard"
        case "openai":
            openaiApiKey = text
            openaiKeyStatus = "Pasted from clipboard"
        case "gemini":
            geminiApiKey = text
        default:
            break
        }
    }

    func testGroqKey() {
        guard !groqApiKey.isEmpty else {
            groqKeyStatus = "Please enter or paste a key first"
            return
        }
        isTestingGroqKey = true
        groqKeyStatus = "Validating..."
        Task {
            do {
                let valid = try await WhisperClient.shared.validateKey(provider: .groq, apiKey: groqApiKey)
                await MainActor.run {
                    self.groqKeyStatus = valid ? "✅ Groq key is valid!" : "❌ Invalid Groq key"
                    self.isTestingGroqKey = false
                }
            } catch {
                await MainActor.run {
                    self.groqKeyStatus = "❌ Connection failed: \(error.localizedDescription)"
                    self.isTestingGroqKey = false
                }
            }
        }
    }

    func testOpenAIKey() {
        guard !openaiApiKey.isEmpty else {
            openaiKeyStatus = "Please enter or paste a key first"
            return
        }
        isTestingOpenAIKey = true
        openaiKeyStatus = "Validating..."
        Task {
            do {
                let valid = try await WhisperClient.shared.validateKey(provider: .openai, apiKey: openaiApiKey)
                await MainActor.run {
                    self.openaiKeyStatus = valid ? "✅ OpenAI key is valid!" : "❌ Invalid OpenAI key"
                    self.isTestingOpenAIKey = false
                }
            } catch {
                await MainActor.run {
                    self.openaiKeyStatus = "❌ Connection failed: \(error.localizedDescription)"
                    self.isTestingOpenAIKey = false
                }
            }
        }
    }

    func loadPreset(_ preset: MathPreset) {
        spokenText = preset.spoken
        compileCustomSpokenText(preset.spoken)
    }
}
