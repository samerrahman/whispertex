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
        // Delay slightly so focus returns to the target application
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // 1. Try CGEvent (Virtual Key 0x09 is 'v')
            let src = CGEventSource(stateID: .combinedSessionState)
            let vKeyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)
            vKeyDown?.flags = .maskCommand
            let vKeyUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
            vKeyUp?.flags = .maskCommand

            vKeyDown?.post(tap: .cghidEventTap)
            vKeyUp?.post(tap: .cghidEventTap)

            // 2. Fallback via AppleScript if CGEvent was blocked by sandboxing
            let appleScript = """
            try
                tell application "System Events"
                    keystroke "v" using command down
                end tell
            end try
            """
            if let script = NSAppleScript(source: appleScript) {
                var err: NSDictionary?
                script.executeAndReturnError(&err)
            }
        }
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
