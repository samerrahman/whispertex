import Foundation
import Carbon

class HotkeyManager {
    static let shared = HotkeyManager()

    private var eventHotKeyRef: EventHotKeyRef?
    var onTrigger: (() -> Void)?

    init() {
        installEventHandler()
    }

    func registerHotkey(keyCode: UInt32 = 37, modifiers: UInt32 = UInt32(cmdKey | shiftKey)) {
        // Keycode 37 is 'L'
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x57544558) // 'WTEX'
        hotKeyID.id = 1

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &eventHotKeyRef
        )

        if status == noErr {
            print("Successfully registered global hotkey (Cmd+Shift+L)")
        } else {
            print("Failed to register hotkey: \(status)")
        }
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
            HotkeyManager.shared.onTrigger?()
            return noErr
        }

        InstallEventHandler(GetEventDispatcherTarget(), handler, 1, &eventType, nil, nil)
    }
}
