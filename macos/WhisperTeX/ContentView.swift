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
        // Automatically check environment variables if empty
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
            state = .error("Failed to start recording: \(error.localizedDescription)")
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

                    // Copy to clipboard
                    PasteboardHelper.shared.copyToClipboard(result.formatted)
                    self.copied = true

                    // Auto-paste if enabled
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

    func compileManual() {
        guard !spokenText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        state = .compiling
        Task {
            do {
                let result = try await LatexCompiler.shared.compile(
                    spoken: spokenText,
                    provider: provider,
                    apiKey: currentApiKey(),
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
                        self.state = .idle
                    }
                }
            } catch {
                await MainActor.run {
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    func selectPreset(_ preset: MathPreset) {
        spokenText = preset.spoken
        compileManual()
    }

    func updateDelimiter(_ newDelimiter: MathDelimiter) {
        delimiter = newDelimiter
        formattedLatex = LatexCompiler.shared.applyDelimiter(raw: rawLatex, delimiter: newDelimiter)
    }
}

struct ContentView: View {
    @StateObject var viewModel = AppViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [Color.green.opacity(0.8), Color.emerald], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 28, height: 28)
                        Text("∫")
                            .font(.system(size: 18, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("WhisperTeX")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("Speech to LaTeX")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                // State indicator pill
                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(viewModel.state.statusText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                .cornerRadius(12)

                // Settings button
                Button(action: { viewModel.showSettings.toggle() }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ScrollView {
                VStack(spacing: 14) {
                    
                    // Push to talk control button
                    Button(action: { viewModel.toggleRecording() }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.state == .recording ? Color.red : Color.green.opacity(0.8))
                                    .frame(width: 44, height: 44)
                                    .shadow(color: viewModel.state == .recording ? .red.opacity(0.5) : .green.opacity(0.3), radius: 8)

                                Image(systemName: viewModel.state == .recording ? "stop.fill" : "mic.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(viewModel.state == .recording ? "Click to Stop Recording" : "Click to Speak Math")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("Or press global hotkey: ⌘+Shift+L")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }

                            Spacer()
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    // Spoken transcript box
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Spoken Mathematical Description")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.gray)
                            Spacer()
                            Button("Compile") {
                                viewModel.compileManual()
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                            .buttonStyle(.plain)
                        }

                        TextEditor(text: $viewModel.spokenText)
                            .font(.system(size: 12))
                            .frame(height: 52)
                            .padding(6)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }

                    // Rendered KaTeX Visual Preview
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Typeset Preview")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)

                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
                                .frame(height: 75)

                            KaTeXView(latex: viewModel.rawLatex)
                                .frame(height: 70)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    }

                    // LaTeX Output Code & Delimiter Selector
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            // Delimiter Pills
                            HStack(spacing: 4) {
                                ForEach(MathDelimiter.allCases) { delim in
                                    Button(action: { viewModel.updateDelimiter(delim) }) {
                                        Text(delim == .display ? "$$" : delim == .inline ? "$" : delim == .bracket ? "\\[\\]" : "raw")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(viewModel.delimiter == delim ? Color.green.opacity(0.2) : Color.clear)
                                            .foregroundColor(viewModel.delimiter == delim ? .green : .gray)
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Spacer()

                            // Copy button
                            Button(action: {
                                PasteboardHelper.shared.copyToClipboard(viewModel.formattedLatex)
                                viewModel.copied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    viewModel.copied = false
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: viewModel.copied ? "checkmark" : "doc.on.doc")
                                    Text(viewModel.copied ? "Copied!" : "Copy")
                                }
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(viewModel.copied ? .green : .white)
                            }
                            .buttonStyle(.plain)
                        }

                        // Code display
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(viewModel.formattedLatex)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.green.opacity(0.9))
                                .padding(8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                    }

                    // Preset Quick Pick
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Quick Math Presets")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)

                        VStack(spacing: 4) {
                            ForEach(SAMPLE_PRESETS) { preset in
                                Button(action: { viewModel.selectPreset(preset) }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(preset.title)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.white)
                                            Text(preset.spoken)
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.right.circle")
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                }
                .padding(16)
            }

            Divider()

            // Footer
            HStack {
                Toggle("Auto-paste at cursor", isOn: $viewModel.autoPaste)
                    .font(.system(size: 11))
                    .toggleStyle(.checkbox)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 360, height: 520)
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView(viewModel: viewModel)
        }
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

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("WhisperTeX Settings")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("LLM & Whisper Provider")
                    .font(.system(size: 12, weight: .semibold))

                Picker("", selection: $viewModel.provider) {
                    ForEach(LLMProvider.allCases) { prov in
                        Text(prov.label).tag(prov)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Groq API Key (Fastest <250ms, Free Tier)")
                        .font(.system(size: 11, weight: .medium))
                    SecureField("gsk_...", text: $viewModel.groqApiKey)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("OpenAI API Key")
                        .font(.system(size: 11, weight: .medium))
                    SecureField("sk-...", text: $viewModel.openaiApiKey)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Gemini API Key")
                        .font(.system(size: 11, weight: .medium))
                    SecureField("AIzaSy...", text: $viewModel.geminiApiKey)
                        .textFieldStyle(.roundedBorder)
                }

                Text("Global Hotkey: ⌘ + Shift + L")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 340, height: 360)
    }
}

extension Color {
    static let emerald = Color(red: 16/255, green: 185/255, blue: 129/255)
}
