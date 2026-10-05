"""
Clipboard and system paste integration.
Supports macOS pbcopy/AppleScript keystroke, Linux xclip/wl-copy, and Windows clip.
"""

import sys
import subprocess
import shutil

def copy_to_clipboard(text: str) -> bool:
    """Copies text to system clipboard."""
    try:
        if sys.platform == "darwin":
            p = subprocess.Popen(["pbcopy"], stdin=subprocess.PIPE)
            p.communicate(text.encode("utf-8"))
            return p.returncode == 0
        elif sys.platform.startswith("linux"):
            if shutil.which("wl-copy"):
                p = subprocess.Popen(["wl-copy"], stdin=subprocess.PIPE)
                p.communicate(text.encode("utf-8"))
                return p.returncode == 0
            elif shutil.which("xclip"):
                p = subprocess.Popen(["xclip", "-selection", "clipboard"], stdin=subprocess.PIPE)
                p.communicate(text.encode("utf-8"))
                return p.returncode == 0
            elif shutil.which("xsel"):
                p = subprocess.Popen(["xsel", "--clipboard", "--input"], stdin=subprocess.PIPE)
                p.communicate(text.encode("utf-8"))
                return p.returncode == 0
        elif sys.platform == "win32":
            p = subprocess.Popen(["clip"], stdin=subprocess.PIPE)
            p.communicate(text.encode("utf-8"))
            return p.returncode == 0
    except Exception as e:
        print(f"Clipboard copy error: {e}", file=sys.stderr)
    return False

def auto_paste() -> bool:
    """Simulates Command+V (or Ctrl+V) paste into the currently focused application."""
    try:
        if sys.platform == "darwin":
            apple_script = """
            try
                tell application "System Events"
                    keystroke "v" using command down
                end tell
            end try
            """
            subprocess.run(["osascript", "-e", apple_script], check=False, stderr=subprocess.DEVNULL)
            return True
        elif sys.platform.startswith("linux"):
            if shutil.which("xdotool"):
                subprocess.run(["xdotool", "key", "ctrl+v"], check=False)
                return True
            elif shutil.which("ydotool"):
                subprocess.run(["ydotool", "key", "29:1", "47:1", "47:0", "29:0"], check=False)
                return True
    except Exception:
        pass
    return False

def notify_user(title: str, message: str) -> None:
    """Sends a desktop notification."""
    try:
        if sys.platform == "darwin":
            safe_msg = message.replace('\\', '\\\\').replace('"', '\\"').replace('\n', ' ')
            safe_title = title.replace('\\', '\\\\').replace('"', '\\"')
            script = f'display notification "{safe_msg}" with title "{safe_title}"'
            subprocess.run(["osascript", "-e", script], check=False, stderr=subprocess.DEVNULL)
        elif sys.platform.startswith("linux") and shutil.which("notify-send"):
            subprocess.run(["notify-send", title, message], check=False)
    except Exception:
        pass
