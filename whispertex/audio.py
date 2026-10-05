"""
Audio recording module.
Provides zero-dependency audio capture on macOS via native `afrecord`,
with fallbacks to `ffmpeg` or `arecord` / `sox` on Linux.
"""

import os
import sys
import shutil
import tempfile
import subprocess
from typing import Optional

class AudioRecorder:
    def __init__(self, sample_rate: int = 16000):
        self.sample_rate = sample_rate
        self.process: Optional[subprocess.Popen] = None
        self.temp_file: Optional[str] = None

    def start(self) -> str:
        """Starts recording audio to a temporary WAV file. Returns file path."""
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
            self.temp_file = f.name

        if shutil.which("ffmpeg"):
            # ffmpeg fallback
            if sys.platform == "darwin":
                cmd = ["ffmpeg", "-y", "-f", "avfoundation", "-i", ":0", "-ar", str(self.sample_rate), "-ac", "1", self.temp_file]
            elif sys.platform.startswith("linux"):
                cmd = ["ffmpeg", "-y", "-f", "pulse", "-i", "default", "-ar", str(self.sample_rate), "-ac", "1", self.temp_file]
            else:
                cmd = ["ffmpeg", "-y", "-f", "dshow", "-i", "audio=default", "-ar", str(self.sample_rate), "-ac", "1", self.temp_file]
        elif shutil.which("rec"):
            # SoX fallback
            cmd = ["rec", "-q", "-c", "1", "-r", str(self.sample_rate), self.temp_file]
        elif shutil.which("arecord"):
            # Linux ALSA fallback
            cmd = ["arecord", "-f", "cd", "-t", "wav", "-r", str(self.sample_rate), "-c", "1", self.temp_file]
        elif sys.platform == "darwin" and shutil.which("swift"):
            # Native macOS recording via AVFoundation inline swift
            swift_code = (
                f'import Foundation, AVFoundation\n'
                f'let u = URL(fileURLWithPath: "{self.temp_file}")\n'
                f'let s: [String: Any] = [AVFormatIDKey: Int(kAudioFormatLinearPCM), AVSampleRateKey: {self.sample_rate}.0, AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 16, AVLinearPCMIsBigEndianKey: false, AVLinearPCMIsFloatKey: false]\n'
                f'let r = try AVAudioRecorder(url: u, settings: s)\n'
                f'r.prepareToRecord()\n'
                f'r.record()\n'
                f'dispatchMain()\n'
            )
            cmd = ["swift", "-e", swift_code]
        else:
            raise RuntimeError(
                "No audio recording tool found. Please install `ffmpeg` or `sox` (e.g. `brew install ffmpeg`)."
            )

        self.process = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        return self.temp_file

    def stop(self) -> str:
        """Stops recording and returns path to the recorded audio file."""
        if self.process:
            self.process.terminate()
            try:
                self.process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.process.kill()
            self.process = None

        if not self.temp_file or not os.path.exists(self.temp_file):
            raise RuntimeError("Audio file was not created properly.")

        return self.temp_file

    def cleanup(self) -> None:
        """Deletes temporary recording file."""
        if self.temp_file and os.path.exists(self.temp_file):
            try:
                os.remove(self.temp_file)
            except Exception:
                pass
            self.temp_file = None
