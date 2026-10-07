import Foundation
import AppKit
import UserNotifications

class PasteboardHelper {
    static let shared = PasteboardHelper()

    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func autoPaste() {
        // If WhisperTeX is the active frontmost app (e.g. user clicked "Paste at Cursor" in WhisperTeX),
        // hide WhisperTeX so focus immediately returns to their previous application (Overleaf, VS Code, Notes, etc.)
        let isWhisperTeXActive = NSApplication.shared.isActive
        if isWhisperTeXActive {
            NSApplication.shared.hide(nil)
        }

        // Delay slightly for window manager to restore active target application focus
        let delay: TimeInterval = isWhisperTeXActive ? 0.25 : 0.08
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.sendPasteKeystroke()
        }
    }

    func sendPasteKeystroke() {
        // Use hidSystemState so modifier keys from physical hotkeys (like Shift in Cmd+Shift+L) do not bleed
        let src = CGEventSource(stateID: .hidSystemState)
        guard let vKeyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true),
              let vKeyUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false) else {
            return
        }
        vKeyDown.flags = .maskCommand
        vKeyUp.flags = .maskCommand

        // Post to both Session Event Tap and HID Event Tap for maximum application compatibility
        vKeyDown.post(tap: .cgSessionEventTap)
        vKeyUp.post(tap: .cgSessionEventTap)
        vKeyDown.post(tap: .cghidEventTap)
        vKeyUp.post(tap: .cghidEventTap)
    }

    func notify(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
