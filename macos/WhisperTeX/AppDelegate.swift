import Cocoa
import SwiftUI
import Carbon

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var viewModel = AppViewModel()
    var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup standard system menu (Edit menu enables Cmd+V paste in text fields)
        setupMainMenu()

        // Setup menu bar popover
        setupPopover()

        // Setup status item in macOS top menu bar
        setupStatusItem()

        // Register global hotkey: Cmd + Shift + L
        setupHotkey()

        // Display the main standalone window on launch
        showMainWindow()

        // Prompt to move to Applications if launched from DMG
        checkAndPromptMoveToApplications()
    }

    // MARK: - Main Application Window
    func showMainWindow() {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 780, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "WhisperTeX — Speech to LaTeX"
        window.minSize = NSSize(width: 720, height: 520)
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.setFrameAutosaveName("WhisperTeXMainWindowFrame")

        let hostingView = NSHostingView(rootView: MainWindowView(viewModel: self.viewModel))
        window.contentView = hostingView

        self.mainWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running in menu bar even when main window is closed
        return false
    }

    // MARK: - Menu Bar Setup
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "∫"
            button.font = NSFont.systemFont(ofSize: 15, weight: .bold)
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 310, height: 230)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView(viewModel: self.viewModel))
        self.popover = popover
    }

    private func setupHotkey() {
        HotkeyManager.shared.onTrigger = { [weak self] in
            DispatchQueue.main.async {
                self?.viewModel.toggleRecording()
                self?.updateStatusIcon()
            }
        }
        HotkeyManager.shared.registerHotkey()
    }

    // MARK: - Standard System Menus (Enables Cmd+V, Cmd+C, Cmd+A, etc.)
    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // 1. WhisperTeX Application Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "WhisperTeX")
        appMenu.addItem(withTitle: "About WhisperTeX", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Open Main Window", action: #selector(openMainWindowAction), keyEquivalent: "o")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide WhisperTeX", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h").keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit WhisperTeX", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // 2. Edit Menu (ESSENTIAL: Allows Cmd+V, Cmd+C, Cmd+X, Cmd+A to work in TextFields & SecureFields)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // 3. Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.zoom(_:)), keyEquivalent: "")
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(withTitle: "WhisperTeX Window", action: #selector(openMainWindowAction), keyEquivalent: "0")
        windowMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc func openMainWindowAction() {
        showMainWindow()
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

    private func checkAndPromptMoveToApplications() {
        let bundlePath = Bundle.main.bundlePath
        if bundlePath.hasPrefix("/Volumes/") {
            let alert = NSAlert()
            alert.messageText = "Move WhisperTeX to Applications?"
            alert.informativeText = "WhisperTeX was opened from a disk image. Would you like to install it in your Applications folder?"
            alert.addButton(withTitle: "Move to Applications")
            alert.addButton(withTitle: "Run From Here")
            alert.alertStyle = .informational

            if alert.runModal() == .alertFirstButtonReturn {
                let dest = "/Applications/WhisperTeX.app"
                try? FileManager.default.removeItem(atPath: dest)
                do {
                    try FileManager.default.copyItem(atPath: bundlePath, toPath: dest)
                    let p = Process()
                    p.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                    p.arguments = [dest]
                    try p.run()
                    NSApplication.shared.terminate(nil)
                } catch {
                    print("Failed to copy to /Applications: \(error)")
                }
            }
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
        app.setActivationPolicy(.regular) // Runs with standard Dock icon, system menus & window support
        app.run()
    }
}
