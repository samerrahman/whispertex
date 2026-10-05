"""
Command Line Interface for WhisperTeX.
Usage:
  whispertex [listen]              Interactive press-Enter push-to-talk
  whispertex convert "<phrase>"    Convert spoken math phrase to LaTeX
  whispertex daemon                Run background global hotkey daemon
  whispertex demo                  Interactive demo of math translations
  whispertex config                Manage API keys and preferences
"""

import sys
import time
import argparse
from whispertex import __version__
from whispertex.config import load_config, save_config, DEFAULT_CONFIG
from whispertex.audio import AudioRecorder
from whispertex.transcriber import transcribe_audio
from whispertex.translator import translate_spoken_to_latex, apply_delimiter
from whispertex.clipboard import copy_to_clipboard, auto_paste, notify_user
from whispertex.presets import PRESETS

def cmd_listen(args, config):
    """Interactive press-to-talk recording from the terminal."""
    recorder = AudioRecorder()

    print("\n" + "=" * 60)
    print(" 🎙️  WhisperTeX - Interactive Math Dictation")
    print(f" STT: {config.get('stt_provider', 'groq')} | LLM: {config.get('provider', 'groq')} | Delimiter: {config.get('delimiter', 'display')}")
    print("=" * 60)
    print("\nPress [ENTER] to start recording your mathematical formula...")
    try:
        input()
    except (KeyboardInterrupt, EOFError):
        print("\nExiting.")
        return

    print("🔴 Recording... Speak standard mathematical English (e.g. 'the integral from zero to infinity...')")
    notify_user("WhisperTeX", "Recording... Speak mathematical English.")
    try:
        recorder.start()
    except Exception as e:
        print(f"\n❌ Error starting recording: {e}")
        return

    print("\nPress [ENTER] when finished speaking...")
    try:
        input()
    except (KeyboardInterrupt, EOFError):
        recorder.stop()
        recorder.cleanup()
        print("\nCanceled.")
        return

    print("⏹️ Stopped recording. Transcribing audio...")
    try:
        audio_path = recorder.stop()
        spoken = transcribe_audio(audio_path, config)
        recorder.cleanup()
    except Exception as e:
        print(f"\n❌ Transcription failed: {e}")
        recorder.cleanup()
        return

    if not spoken.strip():
        print("⚠️ No speech was detected.")
        return

    print(f"\n🗣️  Spoken: \"{spoken}\"")
    print("⚡ Compiling precision LaTeX...")

    try:
        raw_latex = translate_spoken_to_latex(spoken, config)
        delimiter = getattr(args, "delimiter", None) or config.get("delimiter", "display")
        formatted = apply_delimiter(raw_latex, delimiter)

        print("\n" + "─" * 40)
        print("✨ Output LaTeX:")
        print("─" * 40)
        print(formatted)
        print("─" * 40 + "\n")

        # Copy to clipboard
        if copy_to_clipboard(formatted):
            print("📋 Copied to clipboard!")
        
        # Auto-paste if enabled
        if config.get("auto_paste", True) and not getattr(args, "no_paste", False):
            time.sleep(0.2)
            auto_paste()
            print("🚀 Auto-pasted into active window!")
            notify_user("WhisperTeX", f"Pasted: {raw_latex[:40]}...")
        else:
            notify_user("WhisperTeX", "Copied LaTeX to clipboard!")

    except Exception as e:
        print(f"\n❌ LaTeX translation failed: {e}")

def cmd_convert(args, config):
    """Converts a spoken text string directly to LaTeX."""
    phrase = args.phrase.strip()
    if not phrase:
        print("Error: Empty phrase provided.")
        return

    print(f"\n🗣️  Input: \"{phrase}\"")
    delimiter = args.delimiter or config.get("delimiter", "display")

    try:
        raw_latex = translate_spoken_to_latex(phrase, config)
        formatted = apply_delimiter(raw_latex, delimiter)

        print("\n" + "─" * 40)
        print("✨ Output LaTeX:")
        print("─" * 40)
        print(formatted)
        print("─" * 40 + "\n")

        if copy_to_clipboard(formatted):
            print("📋 Copied to clipboard!")

        if getattr(args, "paste", False):
            time.sleep(0.2)
            auto_paste()
            print("🚀 Pasted into active window!")

    except Exception as e:
        print(f"❌ Translation error: {e}")

def cmd_demo(args, config):
    """Runs through preset mathematical phrases to demonstrate capabilities."""
    print("\n" + "=" * 65)
    print(" 🧪 WhisperTeX Mathematical Capabilities Demo")
    print("=" * 65 + "\n")

    for i, p in enumerate(PRESETS, 1):
        print(f"[{i}/{len(PRESETS)}] {p['title']} ({p['category']})")
        print(f"  Spoken:   \"{p['spoken']}\"")
        try:
            latex = translate_spoken_to_latex(p['spoken'], config)
            print(f"  LaTeX:    {latex}")
        except Exception as e:
            print(f"  Error:    {e}")
        print(f"  Note:     {p['description']}\n")

def cmd_config(args, config):
    """Manages configuration and API keys."""
    if args.show:
        print("\n" + "=" * 40)
        print(" WhisperTeX Configuration")
        print("=" * 40)
        for k, v in config.items():
            if "key" in k and v:
                display_v = v[:4] + "..." + v[-4:] if len(v) > 8 else "***"
            else:
                display_v = v
            print(f"  {k:20}: {display_v}")
        print("=" * 40 + "\n")
        return

    changed = False
    if args.groq_key:
        config["groq_api_key"] = args.groq_key
        config["provider"] = "groq"
        config["stt_provider"] = "groq"
        changed = True
        print("✅ Groq API key saved.")

    if args.openai_key:
        config["openai_api_key"] = args.openai_key
        changed = True
        print("✅ OpenAI API key saved.")

    if args.gemini_key:
        config["gemini_api_key"] = args.gemini_key
        changed = True
        print("✅ Gemini API key saved.")

    if args.provider:
        config["provider"] = args.provider
        changed = True
        print(f"✅ LLM Provider set to {args.provider}.")

    if args.stt_provider:
        config["stt_provider"] = args.stt_provider
        changed = True
        print(f"✅ STT Provider set to {args.stt_provider}.")

    if args.delimiter:
        config["delimiter"] = args.delimiter
        changed = True
        print(f"✅ Default delimiter set to {args.delimiter}.")

    if args.auto_paste is not None:
        config["auto_paste"] = args.auto_paste
        changed = True
        print(f"✅ Auto-paste set to {args.auto_paste}.")

    if changed:
        save_config(config)
    else:
        print("No changes specified. Use --help or --show.")

def main():
    parser = argparse.ArgumentParser(
        prog="whispertex",
        description="🎙️ WhisperTeX: Dictate mathematical English and compile to precision LaTeX."
    )
    parser.add_argument("--version", action="version", version=f"%(prog)s {__version__}")
    
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # listen command (default)
    listen_p = subparsers.add_parser("listen", help="Interactive press-to-talk math dictation")
    listen_p.add_argument("-d", "--delimiter", choices=["display", "inline", "bracket", "raw"],
                          help="LaTeX enclosing delimiter")
    listen_p.add_argument("--no-paste", action="store_true", help="Do not auto-paste into active app")

    # convert command
    conv_p = subparsers.add_parser("convert", help="Convert spoken phrase string directly to LaTeX")
    conv_p.add_argument("phrase", help="Spoken mathematical phrase in quotes")
    conv_p.add_argument("-d", "--delimiter", choices=["display", "inline", "bracket", "raw"],
                        help="LaTeX enclosing delimiter")
    conv_p.add_argument("-p", "--paste", action="store_true", help="Auto-paste result into active app")

    # daemon command
    subparsers.add_parser("daemon", help="Run background push-to-talk global hotkey daemon")

    # demo command
    subparsers.add_parser("demo", help="Run benchmark demo across math disciplines")

    # config command
    cfg_p = subparsers.add_parser("config", help="View or update settings & API keys")
    cfg_p.add_argument("--show", action="store_true", help="Show current configuration")
    cfg_p.add_argument("--groq-key", help="Set Groq API key")
    cfg_p.add_argument("--openai-key", help="Set OpenAI API key")
    cfg_p.add_argument("--gemini-key", help="Set Gemini API key")
    cfg_p.add_argument("--provider", choices=["groq", "openai", "gemini", "ollama", "offline"],
                       help="Set LLM provider")
    cfg_p.add_argument("--stt-provider", choices=["groq", "openai", "local"],
                       help="Set Whisper STT provider")
    cfg_p.add_argument("--delimiter", choices=["display", "inline", "bracket", "raw"],
                       help="Set default delimiter")
    cfg_p.add_argument("--auto-paste", type=lambda x: (str(x).lower() in ['true', '1', 'yes']),
                       help="Enable or disable auto-paste (true/false)")

    args = parser.parse_args()
    config = load_config()

    if args.command == "convert":
        cmd_convert(args, config)
    elif args.command == "daemon":
        from whispertex.daemon import run_hotkey_daemon
        run_hotkey_daemon(config)
    elif args.command == "demo":
        cmd_demo(args, config)
    elif args.command == "config":
        cmd_config(args, config)
    else:
        # Default action is listen
        cmd_listen(args, config)

if __name__ == "__main__":
    main()
