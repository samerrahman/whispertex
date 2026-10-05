import Cocoa
import SwiftUI
import Carbon

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var viewModel = AppViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup popover
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 520)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView(viewModel: self.viewModel))
        self.popover = popover

        // Setup status item in macOS top menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "∫"
            button.font = NSFont.systemFont(ofSize: 15, weight: .bold)
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // Register global hotkey: Cmd + Shift + L
        HotkeyManager.shared.onTrigger = { [weak self] in
            DispatchQueue.main.async {
                self?.viewModel.toggleRecording()
                self?.updateStatusIcon()
            }
        }
        HotkeyManager.shared.registerHotkey()
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func updateStatusIcon() {
        guard let button = statusItem.button else { return }
        if viewModel.state == .recording {
            button.title = "🔴"
        } else {
            button.title = "∫"
        }
    }
}

@main
struct WhisperTeXApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // Runs as a menu bar accessory (no dock icon needed)
        app.run()
    }
}
