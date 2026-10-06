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
        let authStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if authStatus == .denied || authStatus == .restricted {
            throw NSError(
                domain: "WhisperTeX",
                code: 100,
                userInfo: [NSLocalizedDescriptionKey: "Microphone access is denied. Please open System Settings -> Privacy & Security -> Microphone and enable WhisperTeX."]
            )
        }

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
                userInfo: [NSLocalizedDescriptionKey: "Microphone recording failed to initialize. Please check Microphone permissions in System Settings -> Privacy & Security -> Microphone."]
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

        let attr = try? FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attr?[.size] as? Int64) ?? 0
        if size < 500 {
            throw NSError(
                domain: "WhisperTeX",
                code: 104,
                userInfo: [NSLocalizedDescriptionKey: "Recorded audio was empty (\(size) bytes). Please ensure your microphone is connected and authorized in System Settings."]
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
