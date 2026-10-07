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
        elif sys.platform == "win32":
            import ctypes
            user32 = ctypes.windll.user32
            # VK_CONTROL = 0x11, 'V' = 0x56, KEYEVENTF_KEYUP = 0x0002
            user32.keybd_event(0x11, 0, 0, 0)
            user32.keybd_event(0x56, 0, 0, 0)
            user32.keybd_event(0x56, 0, 2, 0)
            user32.keybd_event(0x11, 0, 2, 0)
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
        elif sys.platform == "win32":
            safe_msg = message.replace('"', '`"').replace('\n', ' ')
            safe_title = title.replace('"', '`"')
            ps_script = f'''
            [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
            $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
            $textNodes = $template.GetElementsByTagName("text")
            $textNodes.Item(0).AppendChild($template.CreateTextNode("{safe_title}")) | Out-Null
            $textNodes.Item(1).AppendChild($template.CreateTextNode("{safe_msg}")) | Out-Null
            $toast = [Windows.UI.Notifications.ToastNotification]::new($template)
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("WhisperTeX").Show($toast)
            '''
            subprocess.run(["powershell", "-NoProfile", "-Command", ps_script], check=False, stderr=subprocess.DEVNULL)
    except Exception:
        pass
