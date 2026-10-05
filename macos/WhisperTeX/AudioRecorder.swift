import Foundation

class AudioRecorder {
    private var process: Process?
    private var tempAudioURL: URL?

    func start() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("whispertex_\(UUID().uuidString).wav")
        self.tempAudioURL = fileURL

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/afrecord")
        p.arguments = [
            "-f", "WAVE",
            "-c", "1",
            "-r", "16000",
            fileURL.path
        ]
        p.standardOutput = Pipe()
        p.standardError = Pipe()

        try p.run()
        self.process = p
        return fileURL
    }

    func stop() throws -> URL {
        guard let p = self.process, let url = self.tempAudioURL else {
            throw NSError(domain: "WhisperTeX", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active audio recording"])
        }

        p.terminate()
        p.waitUntilExit()
        self.process = nil

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw NSError(domain: "WhisperTeX", code: 2, userInfo: [NSLocalizedDescriptionKey: "Recorded audio file not found"])
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
