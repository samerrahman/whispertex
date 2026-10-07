"""
Background Push-to-Talk Daemon.
Listens for global hotkeys (e.g. Cmd+Shift+L) to record, transcribe, and auto-paste LaTeX.
"""

import sys
import time
from typing import Dict, Any
from whispertex.audio import AudioRecorder
from whispertex.transcriber import transcribe_audio
from whispertex.translator import translate_spoken_to_latex, apply_delimiter
from whispertex.clipboard import copy_to_clipboard, auto_paste, notify_user

def run_hotkey_daemon(config: Dict[str, Any]) -> None:
    """Runs the global hotkey listener using pynput."""
    try:
        from pynput import keyboard
    except ImportError:
        print("\nError: `pynput` is required for global hotkey support.")
        print("Please install it with: pip install pynput\n")
        sys.exit(1)

    default_hotkey = "<cmd>+<shift>+l" if sys.platform == "darwin" else "<ctrl>+<alt>+l"
    hotkey_str = config.get("hotkey", default_hotkey)
    recorder = AudioRecorder()
    is_recording = False

    print("=" * 60)
    print(" 🎙️ WhisperTeX Global Push-to-Talk Daemon Running")
    print(f" Hotkey:    {hotkey_str}")
    print(f" STT:       {config.get('stt_provider', 'groq')}")
    print(f" LLM:       {config.get('provider', 'groq')}")
    print(f" Delimiter: {config.get('delimiter', 'display')}")
    print(f" Auto-paste:{config.get('auto_paste', True)}")
    print("=" * 60)
    print("\nPress the hotkey, speak your mathematical formula, then release.")
    print("Press Ctrl+C to stop.\n")

    def on_hotkey_trigger():
        nonlocal is_recording
        if not is_recording:
            is_recording = True
            try:
                recorder.start()
                notify_user("WhisperTeX", "Recording... Speak mathematical English.")
                print("🔴 Recording started...")
            except Exception as e:
                print(f"Failed to start recording: {e}")
                is_recording = False
        else:
            is_recording = False
            print("⏹️ Recording stopped. Processing...")
            try:
                audio_path = recorder.stop()
                spoken = transcribe_audio(audio_path, config)
                recorder.cleanup()

                if not spoken.strip():
                    print("No speech detected.")
                    return

                print(f"🗣️  Spoken: \"{spoken}\"")
                raw_latex = translate_spoken_to_latex(spoken, config)
                formatted = apply_delimiter(raw_latex, config.get("delimiter", "display"))

                print(f"✨ LaTeX:\n{formatted}\n")
                copy_to_clipboard(formatted)

                if config.get("auto_paste", True):
                    time.sleep(0.15)
                    auto_paste()
                    notify_user("WhisperTeX", f"Pasted: {raw_latex[:40]}...")
                else:
                    notify_user("WhisperTeX", "Copied LaTeX to clipboard!")

            except Exception as e:
                print(f"Error: {e}")
                notify_user("WhisperTeX Error", str(e))
                recorder.cleanup()

    try:
        with keyboard.GlobalHotKeys({hotkey_str: on_hotkey_trigger}) as h:
            h.join()
    except KeyboardInterrupt:
        print("\nWhisperTeX daemon stopped.")
    except Exception as e:
        print(f"Global hotkey listener error: {e}")
        print("Note: On macOS, Accessibility and Input Monitoring permissions may be required.")
