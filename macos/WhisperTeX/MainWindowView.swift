import SwiftUI
import AppKit
import AVFoundation

struct MainWindowView: View {
    @ObservedObject var viewModel: AppViewModel
    @StateObject var permissions = PermissionsManager.shared
    @State private var selectedTab: Int = 0
    @State private var showGroqKey: Bool = false
    @State private var showOpenAIKey: Bool = false
    @State private var showGeminiKey: Bool = false
    @State private var testPasteText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Top Window Header & Tab Selector
            HStack(spacing: 16) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [Color.green.opacity(0.85), Color.green], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 34, height: 34)
                        Text("∫")
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WhisperTeX")
                            .font(.system(size: 15, weight: .bold))
                        Text("Speech to LaTeX for Mac")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Tabs Picker
                Picker("", selection: $selectedTab) {
                    Text("🎙️ Dictate & Preview").tag(0)
                    Text("🔒 Permissions & Setup").tag(1)
                    Text("📖 Math Voice Guide").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(width: 420)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Main Content Area
            Group {
                if selectedTab == 0 {
                    dictationTab
                } else if selectedTab == 1 {
                    permissionsTab
                } else {
                    guideTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Bottom Status Footer
            HStack(spacing: 12) {
                // Status dot
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text(viewModel.state.statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                Text("Global Hotkey: ⌘+Shift+L")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(5)

                Toggle("Auto-Paste at Cursor", isOn: $viewModel.autoPaste)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 740, minHeight: 560)
        .onAppear {
            permissions.checkAll()
        }
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

    // MARK: - Tab 1: Dictate & Preview
    private var dictationTab: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Large Push-to-Talk Action Banner
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.toggleRecording()
                    }) {
                        HStack(spacing: 10) {
                            if viewModel.state == .recording {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 12, height: 12)
                                Text("Stop Recording")
                                    .font(.system(size: 14, weight: .bold))
                            } else {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Start Recording Math")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.state == .recording ? Color.red : Color.accentColor)
                        )
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.state == .recording ? "Listening... Speak your mathematical equation clearly" : "Click button or press ⌘+Shift+L anywhere on macOS")
                            .font(.system(size: 13, weight: .semibold))
                        Text(viewModel.state == .recording ? "Tap again when finished to compile into LaTeX" : "Dictate standard English (e.g. 'fraction of 1 over square root of 2 pi')")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Picker("Delimiter:", selection: $viewModel.delimiter) {
                        ForEach(MathDelimiter.allCases) { d in
                            Text(d.label).tag(d)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                    .onChange(of: viewModel.delimiter) { newDelim in
                        viewModel.updateDelimiter(newDelim)
                    }
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // Panel 1: What WhisperTeX Heard (Spoken Words)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("What WhisperTeX Heard (Recognized Speech)", systemImage: "waveform.and.mic")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)

                        Spacer()

                        Button(action: {
                            viewModel.compileCustomSpokenText()
                        }) {
                            Label("Recompile to LaTeX", systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.state == .recording || viewModel.state == .transcribing)
                    }

                    TextEditor(text: $viewModel.spokenText)
                        .font(.system(size: 13, design: .serif))
                        .frame(height: 70)
                        .padding(6)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )

                    Text("Tip: You can edit what it heard above at any time and click 'Recompile to LaTeX'.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // Panel 2: Live KaTeX Typeset Preview
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Rendered LaTeX Formula Preview", systemImage: "function")
                            .font(.system(size: 13, weight: .bold))

                        Spacer()

                        Button(action: {
                            PasteboardHelper.shared.copyToClipboard(viewModel.formattedLatex)
                            viewModel.copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                viewModel.copied = false
                            }
                        }) {
                            Label(viewModel.copied ? "Copied!" : "Copy LaTeX", systemImage: viewModel.copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: {
                            PasteboardHelper.shared.copyToClipboard(viewModel.formattedLatex)
                            PasteboardHelper.shared.autoPaste()
                        }) {
                            Label("Paste at Cursor", systemImage: "arrow.right.doc.on.clipboard")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                    }

                    // KaTeX WebView
                    KaTeXView(latex: viewModel.rawLatex)
                        .frame(height: 110)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )

                    // Formatted LaTeX text box
                    Text(viewModel.formattedLatex)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.secondary.opacity(0.08))
                        .cornerRadius(6)
                }
                .padding(14)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding(18)
        }
    }

    // MARK: - Tab 2: Permissions & System Setup
    private var permissionsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Section 1: System Permissions Diagnostics
                VStack(alignment: .leading, spacing: 14) {
                    Text("macOS System Permissions")
                        .font(.system(size: 14, weight: .bold))

                    // 1. Microphone Permission
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(permissions.microphoneStatus == .authorized ? .green : .red)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Microphone Access")
                                    .font(.system(size: 13, weight: .semibold))
                                statusBadge(
                                    text: permissions.microphoneStatus == .authorized ? "Granted" : (permissions.microphoneStatus == .denied ? "Denied" : "Not Requested"),
                                    color: permissions.microphoneStatus == .authorized ? .green : .red
                                )
                            }
                            Text("Allows WhisperTeX to record your spoken mathematics equations via your input microphone.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)

                            HStack(spacing: 10) {
                                if permissions.microphoneStatus != .authorized {
                                    Button("Request Microphone Access") {
                                        permissions.requestMicrophone()
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                Button("Open System Microphone Settings") {
                                    permissions.openMicrophoneSettings()
                                }
                                .buttonStyle(.bordered)

                                Button(permissions.isTestingMicrophone ? "Recording 2s..." : "Test Microphone Sample") {
                                    permissions.testMicrophone()
                                }
                                .buttonStyle(.bordered)
                                .disabled(permissions.isTestingMicrophone)
                            }
                            .padding(.top, 4)

                            if let msg = permissions.micTestMessage {
                                Text(msg)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.accentColor)
                                    .padding(.top, 2)
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)

                    // 2. Accessibility Permission
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "accessibility.fill")
                            .font(.system(size: 28))
                            .foregroundColor(permissions.isAccessibilityGranted ? .green : .orange)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Accessibility (Auto-Paste at Cursor)")
                                    .font(.system(size: 13, weight: .semibold))
                                statusBadge(
                                    text: permissions.isAccessibilityGranted ? "Granted" : "Action Required",
                                    color: permissions.isAccessibilityGranted ? .green : .orange
                                )
                            }
                            Text("Allows WhisperTeX to simulate Cmd+V so that compiled equations appear directly wherever your cursor is blinking across apps like Overleaf, VS Code, Google Docs, Notion, Notes, etc.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)

                            if !permissions.isAccessibilityGranted {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 10) {
                                        Button("Open Accessibility Settings") {
                                            permissions.requestAccessibility()
                                        }
                                        .buttonStyle(.borderedProminent)

                                        Button("Fix Stale Permission Cache") {
                                            permissions.resetPermissionCache()
                                        }
                                        .buttonStyle(.bordered)

                                        Button("Re-check Status") {
                                            permissions.checkAccessibility()
                                        }
                                        .buttonStyle(.bordered)
                                    }

                                    Text("⚠️ If System Settings already shows WhisperTeX as turned ON, macOS has an outdated security cache from an older build. Click \"Fix Stale Permission Cache\", then toggle WhisperTeX ON in System Settings.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.orange)
                                        .fixedSize(horizontal: false, vertical: true)

                                    if let status = permissions.cacheResetStatus {
                                        Text(status)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.top, 4)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 10) {
                                        Button("Open Accessibility Settings") {
                                            permissions.requestAccessibility()
                                        }
                                        .buttonStyle(.bordered)

                                        Button("Test Keystroke Simulation") {
                                            PasteboardHelper.shared.copyToClipboard("\\int_0^\\infty e^{-x}\\,dx = 1")
                                            PasteboardHelper.shared.sendPasteKeystroke()
                                        }
                                        .buttonStyle(.bordered)

                                        Button("Re-check Status") {
                                            permissions.checkAccessibility()
                                        }
                                        .buttonStyle(.bordered)
                                    }

                                    HStack(spacing: 8) {
                                        TextField("Click here and press 'Test Keystroke Simulation'...", text: $testPasteText)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .font(.system(size: 11))
                                            .frame(maxWidth: 340)

                                        if !testPasteText.isEmpty {
                                            Button("Clear") {
                                                testPasteText = ""
                                            }
                                            .font(.system(size: 10))
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)

                // Section 2: AI Provider & API Keys Configuration
                VStack(alignment: .leading, spacing: 14) {
                    Text("AI Providers & API Keys")
                        .font(.system(size: 14, weight: .bold))

                    Picker("Active Transcription & LLM Engine:", selection: $viewModel.provider) {
                        ForEach(LLMProvider.allCases) { p in
                            Text(p.label).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 360)

                    // Groq API Key
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Groq API Key (Recommended - Whisper Large v3 <300ms)")
                                .font(.system(size: 12, weight: .semibold))
                            Spacer()
                            Button("Get Free Groq Key ↗") {
                                if let url = URL(string: "https://console.groq.com/keys") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundColor(.accentColor)
                        }

                        HStack(spacing: 8) {
                            if showGroqKey {
                                TextField("gsk_...", text: $viewModel.groqApiKey)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                SecureField("gsk_...", text: $viewModel.groqApiKey)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Button(action: { showGroqKey.toggle() }) {
                                Image(systemName: showGroqKey ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.bordered)

                            Button(action: {
                                viewModel.pasteFromClipboard(for: "groq")
                            }) {
                                Label("Paste", systemImage: "doc.on.clipboard")
                            }
                            .buttonStyle(.borderedProminent)

                            Button(action: {
                                viewModel.testGroqKey()
                            }) {
                                Text(viewModel.isTestingGroqKey ? "Testing..." : "Test Key")
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewModel.isTestingGroqKey || viewModel.groqApiKey.isEmpty)
                        }

                        if let status = viewModel.groqKeyStatus {
                            Text(status)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(status.contains("✅") ? .green : .red)
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)

                    // OpenAI API Key
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("OpenAI API Key (Whisper-1 & GPT-4o-mini)")
                                .font(.system(size: 12, weight: .semibold))
                            Spacer()
                            Button("Get OpenAI Key ↗") {
                                if let url = URL(string: "https://platform.openai.com/api-keys") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 11))
                            .foregroundColor(.accentColor)
                        }

                        HStack(spacing: 8) {
                            if showOpenAIKey {
                                TextField("sk-...", text: $viewModel.openaiApiKey)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                SecureField("sk-...", text: $viewModel.openaiApiKey)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Button(action: { showOpenAIKey.toggle() }) {
                                Image(systemName: showOpenAIKey ? "eye.slash" : "eye")
                            }
                            .buttonStyle(.bordered)

                            Button(action: {
                                viewModel.pasteFromClipboard(for: "openai")
                            }) {
                                Label("Paste", systemImage: "doc.on.clipboard")
                            }
                            .buttonStyle(.borderedProminent)

                            Button(action: {
                                viewModel.testOpenAIKey()
                            }) {
                                Text(viewModel.isTestingOpenAIKey ? "Testing..." : "Test Key")
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewModel.isTestingOpenAIKey || viewModel.openaiApiKey.isEmpty)
                        }

                        if let status = viewModel.openaiKeyStatus {
                            Text(status)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(status.contains("✅") ? .green : .red)
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                }
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding(18)
        }
    }

    // MARK: - Tab 3: Math Voice Guide
    private var guideTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("How to Dictate Advanced Mathematics")
                        .font(.system(size: 15, weight: .bold))
                    Text("You do not need to memorize LaTeX codes. Speak natural mathematical English and WhisperTeX resolves Greek letters, differential operators, indices, and fractions.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                ForEach(SAMPLE_PRESETS) { preset in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(preset.title)
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            Text(preset.category)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.12))
                                .cornerRadius(4)

                            Button("Load & Test") {
                                viewModel.loadPreset(preset)
                                selectedTab = 0
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 11))
                        }

                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Spoken English:")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text("“\(preset.spoken)”")
                                    .font(.system(size: 12, design: .serif))
                                    .italic()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Expected Output:")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text("$\(preset.expected)$")
                                    .font(.system(size: 12, design: .monospaced))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
            .padding(18)
        }
    }

    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .cornerRadius(4)
    }
}
