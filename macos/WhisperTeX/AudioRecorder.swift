import Foundation
import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private var tempAudioURL: URL?

    func requestMicrophonePermission() async -> Bool {
        if #available(macOS 14.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func start() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("whispertex_\(UUID().uuidString).wav")
        self.tempAudioURL = fileURL

        // 16kHz mono 16-bit linear PCM WAV format
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]

        let audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder.delegate = self

        guard audioRecorder.prepareToRecord() && audioRecorder.record() else {
            throw NSError(
                domain: "WhisperTeX",
                code: 101,
                userInfo: [NSLocalizedDescriptionKey: "Microphone recording failed to initialize. Please verify Microphone permissions in System Settings -> Privacy & Security -> Microphone."]
            )
        }

        self.recorder = audioRecorder
        return fileURL
    }

    func stop() throws -> URL {
        guard let rec = self.recorder, let url = self.tempAudioURL else {
            throw NSError(
                domain: "WhisperTeX",
                code: 102,
                userInfo: [NSLocalizedDescriptionKey: "No active audio recording to stop."]
            )
        }

        rec.stop()
        self.recorder = nil

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw NSError(
                domain: "WhisperTeX",
                code: 103,
                userInfo: [NSLocalizedDescriptionKey: "Recorded audio file not found on disk."]
            )
        }

        return url
    }

    func cleanup() {
        if let url = self.tempAudioURL {
            try? FileManager.default.removeItem(at: url)
            self.tempAudioURL = nil
        }
    }
}
