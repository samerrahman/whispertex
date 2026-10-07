import Foundation
import SwiftUI
import AVFoundation
import ApplicationServices

@MainActor
class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()

    @Published var isAccessibilityGranted: Bool = false
    @Published var microphoneStatus: AVAuthorizationStatus = .notDetermined
    @Published var isTestingMicrophone: Bool = false
    @Published var micTestMessage: String? = nil
    @Published var cacheResetStatus: String? = nil

    private var testRecorder: AVAudioRecorder?
    private var testAudioURL: URL?
    private var pollTimer: Timer?

    init() {
        checkAll()
        startMonitoring()
    }

    func startMonitoring() {
        // Automatically re-check when user focuses WhisperTeX (e.g. returns from System Settings)
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkAll()
            }
        }

        // Live polling every 1.5s to detect permission grant without requiring a click
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAccessibility()
                self?.checkMicrophone()
            }
        }
    }

    func checkAll() {
        checkAccessibility()
        checkMicrophone()
    }

    func checkAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        let granted = AXIsProcessTrustedWithOptions(options)
        if isAccessibilityGranted != granted {
            isAccessibilityGranted = granted
            if granted {
                cacheResetStatus = nil
            }
        }
    }

    func requestAccessibility() {
        // Prompt system dialog if not already enabled
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        isAccessibilityGranted = AXIsProcessTrustedWithOptions(options)
        if !isAccessibilityGranted {
            openAccessibilitySettings()
        }
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func resetPermissionCache() {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.samerrahman.whispertex"
        cacheResetStatus = "Resetting macOS security cache..."

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        task.arguments = ["reset", "Accessibility", bundleID]

        do {
            try task.run()
            task.waitUntilExit()

            // Prompt system to register current binary
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)

            // Re-open System Settings
            openAccessibilitySettings()

            cacheResetStatus = "✅ Cache reset. In System Settings, please toggle WhisperTeX ON."
        } catch {
            cacheResetStatus = "⚠️ Error resetting cache: \(error.localizedDescription)"
        }
    }

    func checkMicrophone() {
        microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    }

    func requestMicrophone() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] _ in
            DispatchQueue.main.async {
                self?.checkMicrophone()
            }
        }
    }

    func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }

    func testMicrophone() {
        guard !isTestingMicrophone else { return }
        checkMicrophone()
        if microphoneStatus != .authorized {
            requestMicrophone()
            micTestMessage = "Requesting microphone access..."
            return
        }

        isTestingMicrophone = true
        micTestMessage = "Recording 2-second audio sample..."

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("whispertex_test_\(UUID().uuidString).wav")
        self.testAudioURL = fileURL

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]

        do {
            let rec = try AVAudioRecorder(url: fileURL, settings: settings)
            rec.prepareToRecord()
            rec.record()
            self.testRecorder = rec

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }
                self.testRecorder?.stop()
                self.testRecorder = nil

                if let url = self.testAudioURL, FileManager.default.fileExists(atPath: url.path) {
                    let attr = try? FileManager.default.attributesOfItem(atPath: url.path)
                    let size = (attr?[.size] as? Int64) ?? 0
                    if size > 1000 {
                        self.micTestMessage = "✅ Microphone working! Captured \(size / 1024) KB audio sample."
                    } else {
                        self.micTestMessage = "⚠️ Audio file created but is silent/empty (\(size) bytes). Check input device."
                    }
                    try? FileManager.default.removeItem(at: url)
                } else {
                    self.micTestMessage = "❌ Failed to create test audio file."
                }
                self.isTestingMicrophone = false
            }
        } catch {
            self.micTestMessage = "❌ Error testing microphone: \(error.localizedDescription)"
            self.isTestingMicrophone = false
        }
    }
}
