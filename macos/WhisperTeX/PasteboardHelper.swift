import Foundation
import AppKit
import Carbon.HIToolbox
import UserNotifications

@MainActor
final class PasteboardHelper {
    static let shared = PasteboardHelper()

    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    private var lastPasteTime: Date = .distantPast
    private var pasteInFlight = false

    /// Every physical modifier key (Carbon virtual key codes), left and right.
    private static let modifierKeys: [CGKeyCode] = [
        kVK_Command, kVK_RightCommand, kVK_Shift, kVK_RightShift,
        kVK_Option, kVK_RightOption, kVK_Control, kVK_RightControl, kVK_Function,
    ].map { CGKeyCode($0) }

    /// Device-independent modifier bits that a stale synthetic event could leave latched.
    private static let latchableFlags: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl]

    /// .maskCommand plus NX_DEVICELCMDKEYMASK (0x08), i.e. "left Command is down",
    /// which is what a real keyboard reports and what CGEvent itself produces for kVK_Command down.
    private static let commandDown = CGEventFlags(rawValue: CGEventFlags.maskCommand.rawValue | 0x08)

    func autoPaste() {
        let now = Date()
        guard !pasteInFlight, now.timeIntervalSince(lastPasteTime) > 0.6 else { return }
        lastPasteTime = now
        pasteInFlight = true

        // If WhisperTeX is frontmost (e.g. "Paste at Cursor" button), hide it so the previous app regains focus.
        let wasActive = NSApp.isActive
        if wasActive { NSApp.hide(nil) }
        let focusDelay: UInt64 = wasActive ? 250_000_000 : 80_000_000

        Task { @MainActor in
            defer { self.pasteInFlight = false }
            try? await Task.sleep(nanoseconds: focusDelay)
            // Never interleave a synthetic Cmd+V with the user's (or Voice Control's) own
            // modifier presses, e.g. a still-held Cmd+Shift from the Cmd+Shift+L hotkey.
            await self.waitForModifierRelease(timeout: 1.0)
            self.sendPasteKeystroke()
        }
    }

    /// Uses per-key state, not flagsState: the flags table is the thing older builds corrupted,
    /// while they never posted modifier key codes, so key state still reflects reality.
    private func anyModifierKeyDown() -> Bool {
        Self.modifierKeys.contains { key in
            CGEventSource.keyState(.hidSystemState, key: key) ||
                CGEventSource.keyState(.combinedSessionState, key: key)
        }
    }

    private func waitForModifierRelease(timeout: TimeInterval) async {
        let deadline = Date().addingTimeInterval(timeout)
        while anyModifierKeyDown(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    /// Posts a complete, balanced Cmd+V: Command down, V down, V up, Command up.
    /// The final event carries no modifier flags (other than Caps Lock, preserved as found),
    /// so the session's modifier state is always left exactly as it was found ("Command up").
    func sendPasteKeystroke() {
        guard CGPreflightPostEventAccess() else {
            notify(title: "WhisperTeX", message: "LaTeX copied. Grant Accessibility access to paste automatically.")
            return
        }
        // .combinedSessionState is the source Apple documents for apps posting inside a login session.
        // NEVER .hidSystemState (reserved for daemons/drivers; writes into the hardware modifier table)
        // and NEVER post to .cghidEventTap.
        guard let src = CGEventSource(stateID: .combinedSessionState) else { return }

        let cmd = CGKeyCode(kVK_Command)
        let v = Self.keyCodeForV()
        // Build all four first: never post a Command-down unless its Command-up exists.
        guard let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: cmd, keyDown: true),
              let vDown = CGEvent(keyboardEventSource: src, virtualKey: v, keyDown: true),
              let vUp = CGEvent(keyboardEventSource: src, virtualKey: v, keyDown: false),
              let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: cmd, keyDown: false)
        else { return }

        // Preserve Caps Lock as it currently is; never set or clear it.
        let caps = CGEventSource.flagsState(.combinedSessionState).intersection(.maskAlphaShift)
        let held = Self.commandDown.union(caps)
        cmdDown.flags = held // flagsChanged: Command pressed
        vDown.flags = held   // explicit: no Shift/Option bleed (Cmd+Shift+V is a different command)
        vUp.flags = held
        cmdUp.flags = caps   // flagsChanged: Command released, no modifiers left

        for event in [cmdDown, vDown, vUp, cmdUp] {
            event.post(tap: .cgSessionEventTap)
        }
    }

    /// Transitional clean-up for sessions already corrupted by builds <= 0.2.4, which posted
    /// Command-flagged events from a .hidSystemState source and never released Command.
    /// Fires only when a modifier flag is set but no modifier key is physically down.
    /// It posts key-ups with empty flags from the same (HID) table those builds wrote to; it can only clear state.
    func releaseStaleModifiersIfNeeded() {
        let latched = CGEventSource.flagsState(.hidSystemState)
            .union(CGEventSource.flagsState(.combinedSessionState))
            .intersection(Self.latchableFlags)
        guard !latched.isEmpty, !anyModifierKeyDown(), CGPreflightPostEventAccess() else { return }
        for state in [CGEventSourceStateID.hidSystemState, .combinedSessionState] {
            guard let src = CGEventSource(stateID: state) else { continue }
            for key in [kVK_Command, kVK_Shift, kVK_Option, kVK_Control] {
                guard let up = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(key), keyDown: false) else { continue }
                up.flags = CGEventSource.flagsState(state).intersection(.maskAlphaShift) // keep Caps Lock
                up.post(tap: .cgSessionEventTap)
            }
        }
    }

    /// The key code that types "v" while Command is held in the current keyboard layout.
    /// kVK_ANSI_V is a physical key position; on layouts such as Dvorak it would send Cmd+K instead.
    private static func keyCodeForV() -> CGKeyCode {
        let fallback = CGKeyCode(kVK_ANSI_V)
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return fallback }
        let data = Unmanaged<CFData>.fromOpaque(raw).takeUnretainedValue()
        guard let bytes = CFDataGetBytePtr(data) else { return fallback }
        let layout = UnsafeRawPointer(bytes).assumingMemoryBound(to: UCKeyboardLayout.self)
        let commandModifier = UInt32((cmdKey >> 8) & 0xFF)
        let target = UniChar(UInt8(ascii: "v"))

        func produces(_ code: CGKeyCode) -> Bool {
            var deadKeyState: UInt32 = 0
            var length = 0
            var chars = [UniChar](repeating: 0, count: 4)
            let status = UCKeyTranslate(layout, code, UInt16(kUCKeyActionDown), commandModifier,
                                        UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit),
                                        &deadKeyState, chars.count, &length, &chars)
            return status == noErr && length == 1 && chars[0] == target
        }

        if produces(fallback) { return fallback }
        return (0..<CGKeyCode(128)).first(where: produces) ?? fallback
    }

    func notify(title: String, message: String) {
        guard Bundle.main.bundleIdentifier != nil else { return } // UNUserNotificationCenter traps when unbundled
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
