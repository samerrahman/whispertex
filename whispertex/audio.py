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

        if sys.platform == "darwin" and shutil.which("afrecord"):
            # macOS native audio recording: 16kHz mono WAV
            cmd = [
                "afrecord",
                "-f", "WAVE",
                "-c", "1",
                "-r", str(self.sample_rate),
                self.temp_file
            ]
        elif shutil.which("ffmpeg"):
            # ffmpeg fallback
            if sys.platform == "darwin":
                cmd = ["ffmpeg", "-y", "-f", "avfoundation", "-i", ":0", "-ar", str(self.sample_rate), "-ac", "1", self.temp_file]
            elif sys.platform.startswith("linux"):
                cmd = ["ffmpeg", "-y", "-f", "pulse", "-i", "default", "-ar", str(self.sample_rate), "-ac", "1", self.temp_file]
            else:
                cmd = ["ffmpeg", "-y", "-f", "dshow", "-i", "audio=default", "-ar", str(self.sample_rate), "-ac", "1", self.temp_file]
        elif shutil.which("arecord"):
            # Linux ALSA fallback
            cmd = ["arecord", "-f", "cd", "-t", "wav", "-r", str(self.sample_rate), "-c", "1", self.temp_file]
        elif shutil.which("rec"):
            # SoX fallback
            cmd = ["rec", "-q", "-c", "1", "-r", str(self.sample_rate), self.temp_file]
        else:
            raise RuntimeError(
                "No audio recording tool found. On macOS, `afrecord` is built-in. "
                "On other platforms, please install `ffmpeg` or `sox`."
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
