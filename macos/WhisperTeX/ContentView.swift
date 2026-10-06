import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 11) {
            // Header: Status, Window button, Settings toggle & Quit
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(viewModel.state.statusText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 8) {
                    // Button to open full standalone window
                    Button(action: {
                        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                            appDelegate.showMainWindow()
                        }
                    }) {
                        Image(systemName: "macwindow")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Open Full WhisperTeX Window")

                    // Toggle Settings
                    Button(action: { viewModel.showSettings.toggle() }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 11))
                            .foregroundColor(viewModel.showSettings ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")

                    // Quit
                    Button(action: { NSApplication.shared.terminate(nil) }) {
                        Image(systemName: "power")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Quit WhisperTeX")
                }
            }

            if viewModel.showSettings {
                // Settings view
                VStack(alignment: .leading, spacing: 10) {
                    Text("Settings & API Keys")
                        .font(.system(size: 12, weight: .bold))

                    Picker("Provider", selection: $viewModel.provider) {
                        ForEach(LLMProvider.allCases) { prov in
                            Text(prov.label).tag(prov)
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 11))

                    if viewModel.provider == .groq {
                        HStack(spacing: 4) {
                            SecureField("Groq API Key (gsk_...)", text: $viewModel.groqApiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                            Button("Paste") {
                                viewModel.pasteFromClipboard(for: "groq")
                            }
                            .buttonStyle(.borderedProminent)
                            .font(.system(size: 10))
                        }
                    } else if viewModel.provider == .openai {
                        HStack(spacing: 4) {
                            SecureField("OpenAI API Key (sk-...)", text: $viewModel.openaiApiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                            Button("Paste") {
                                viewModel.pasteFromClipboard(for: "openai")
                            }
                            .buttonStyle(.borderedProminent)
                            .font(.system(size: 10))
                        }
                    } else if viewModel.provider == .gemini {
                        HStack(spacing: 4) {
                            SecureField("Gemini API Key (AIza...)", text: $viewModel.geminiApiKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 11))
                            Button("Paste") {
                                viewModel.pasteFromClipboard(for: "gemini")
                            }
                            .buttonStyle(.borderedProminent)
                            .font(.system(size: 10))
                        }
                    }

                    HStack {
                        Toggle("Auto-paste at cursor", isOn: $viewModel.autoPaste)
                            .font(.system(size: 11))
                            .toggleStyle(.checkbox)

                        Spacer()

                        Button("Permissions Setup ↗") {
                            if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                                appDelegate.showMainWindow()
                            }
                        }
                        .font(.system(size: 10))
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .cornerRadius(8)
            } else {
                // Push-to-talk button & Hotkey hint
                HStack(spacing: 12) {
                    Button(action: { viewModel.toggleRecording() }) {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.state == .recording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text(viewModel.state == .recording ? "Stop Recording" : "Dictate Math")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.state == .recording ? Color.red : Color.green.opacity(0.85))
                        .cornerRadius(16)
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
                        .frame(height: 64)

                    KaTeXView(latex: viewModel.rawLatex)
                        .frame(height: 60)
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
                    .frame(width: 155)

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

                // Spoken transcript (what it heard)
                if !viewModel.spokenText.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Heard:")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        Text("\"\(viewModel.spokenText)\"")
                            .font(.system(size: 10))
                            .foregroundColor(.primary.opacity(0.85))
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .frame(width: 310)
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .idle: return .gray
        case .recording: return .red
        case .transcribing: return .orange
        case .compiling: return .blue
        case .success: return .green
        case .error: return .red
        }
    }
}
