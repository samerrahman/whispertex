import SwiftUI

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

    @AppStorage("groq_api_key") var groqApiKey: String = ""
    @AppStorage("openai_api_key") var openaiApiKey: String = ""
    @AppStorage("gemini_api_key") var geminiApiKey: String = ""

    private let recorder = AudioRecorder()

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
        case .groq: return groqApiKey
        case .openai: return openaiApiKey
        case .gemini: return geminiApiKey
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
                
                let transcript: String
                if provider == .offline || apiKey.isEmpty {
                    transcript = spokenText.isEmpty ? "The integral from zero to infinity of x squared times e to the minus x dx equals two" : spokenText
                } else {
                    transcript = try await WhisperClient.shared.transcribe(fileURL: audioURL, provider: provider, apiKey: apiKey)
                }

                await MainActor.run {
                    self.spokenText = transcript
                    self.state = .compiling
                }

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

    func updateDelimiter(_ newDelimiter: MathDelimiter) {
        delimiter = newDelimiter
        formattedLatex = LatexCompiler.shared.applyDelimiter(raw: rawLatex, delimiter: newDelimiter)
    }
}

struct ContentView: View {
    @StateObject var viewModel = AppViewModel()

    var body: some View {
        VStack(spacing: 11) {
            // Header: Status, Settings toggle & Quit
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(viewModel.state.statusText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Spacer()

                HStack(spacing: 10) {
                    Button(action: { viewModel.showSettings.toggle() }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12))
                            .foregroundColor(viewModel.showSettings ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        Image(systemName: "power")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.showSettings {
                // Settings view
                VStack(alignment: .leading, spacing: 10) {
                    Text("Settings")
                        .font(.system(size: 12, weight: .bold))

                    Picker("Provider", selection: $viewModel.provider) {
                        ForEach(LLMProvider.allCases) { prov in
                            Text(prov.label).tag(prov)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 11))

                    if viewModel.provider == .groq {
                        SecureField("Groq API Key (gsk_...)", text: $viewModel.groqApiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))
                    } else if viewModel.provider == .openai {
                        SecureField("OpenAI API Key (sk-...)", text: $viewModel.openaiApiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))
                    } else if viewModel.provider == .gemini {
                        SecureField("Gemini API Key (AIza...)", text: $viewModel.geminiApiKey)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))
                    }

                    Toggle("Auto-paste at cursor", isOn: $viewModel.autoPaste)
                        .font(.system(size: 11))
                        .toggleStyle(.checkbox)
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)
            } else {
                // Push-to-talk button & Hotkey hint
                HStack(spacing: 12) {
                    Button(action: { viewModel.toggleRecording() }) {
                        HStack(spacing: 7) {
                            Image(systemName: viewModel.state == .recording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text(viewModel.state == .recording ? "Stop Recording" : "Dictate Math")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(viewModel.state == .recording ? Color.red : Color.green.opacity(0.85))
                        .cornerRadius(18)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("⌘+Shift+L")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                        .cornerRadius(6)
                        .foregroundColor(.secondary)
                }

                // Rendered KaTeX equation preview
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
                        .frame(height: 68)

                    KaTeXView(latex: viewModel.rawLatex)
                        .frame(height: 64)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

                // Delimiter selector and Copy button
                HStack(spacing: 8) {
                    Picker("", selection: Binding(
                        get: { viewModel.delimiter },
                        set: { viewModel.updateDelimiter($0) }
                    )) {
                        Text("$$").tag(MathDelimiter.display)
                        Text("$").tag(MathDelimiter.inline)
                        Text("\\[\\]").tag(MathDelimiter.bracket)
                        Text("raw").tag(MathDelimiter.raw)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)

                    Spacer()

                    Button(action: {
                        PasteboardHelper.shared.copyToClipboard(viewModel.formattedLatex)
                        viewModel.copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            viewModel.copied = false
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.copied ? "checkmark" : "doc.on.doc")
                            Text(viewModel.copied ? "Copied" : "Copy")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(viewModel.copied ? .green : .primary)
                    }
                    .buttonStyle(.plain)
                }

                // Spoken transcript (subtle single line)
                if !viewModel.spokenText.isEmpty {
                    Text("\"\(viewModel.spokenText)\"")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 2)
                }
            }
        }
        .padding(13)
        .frame(width: 300)
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .idle: return .green
        case .recording: return .red
        case .transcribing, .compiling: return .yellow
        case .success: return .green
        case .error: return .red
        }
    }
}
