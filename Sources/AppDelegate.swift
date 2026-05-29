import AppKit
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowControllers: [NotepadWindowController] = []
    private var autocorrectMenuItem: NSMenuItem!
    private var pendingFileURL: URL?

    private var isAutocorrectEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "autocorrect") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "autocorrect") }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        let wc = spawnWindow()
        if let url = pendingFileURL {
            wc.loadFile(url: url)
            pendingFileURL = nil
        } else {
            wc.loadScratchpad()
        }
        applyAutocorrect(isAutocorrectEnabled)
        NSApp.activate(ignoringOtherApps: true)

        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.windowControllers.forEach { $0.saveScratchpad() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowControllers.forEach { $0.saveScratchpad() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // MARK: - Window management

    @discardableResult
    private func spawnWindow() -> NotepadWindowController {
        let wc = NotepadWindowController()
        windowControllers.append(wc)
        wc.showWindow(nil)

        if windowControllers.count == 1 {
            wc.window?.setFrameAutosaveName("NotepadMainWindow")
        } else if let prev = windowControllers.dropLast().last?.window,
                  let cur = wc.window {
            let o: CGFloat = 22
            cur.setFrameOrigin(NSPoint(x: prev.frame.origin.x + o,
                                       y: prev.frame.origin.y - o))
        }

        wc.textView.isAutomaticSpellingCorrectionEnabled = isAutocorrectEnabled
        wc.textView.isAutomaticQuoteSubstitutionEnabled = isAutocorrectEnabled
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: wc.window,
            queue: .main
        ) { [weak self, weak wc] _ in
            self?.windowControllers.removeAll { $0 === wc }
        }
        return wc
    }

    private var keyWC: NotepadWindowController? {
        windowControllers.first { $0.window?.isKeyWindow == true } ?? windowControllers.last
    }

    // MARK: - Open from Finder / drag-and-drop

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        guard !windowControllers.isEmpty else {
            pendingFileURL = url
            return true
        }
        spawnWindow().loadFile(url: url)
        return true
    }

    // MARK: - Menu

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(
            title: "About Notepad++",
            action: #selector(showAbout(_:)),
            keyEquivalent: ""
        ))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(
            title: "Quit Notepad++",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        let fileItem = NSMenuItem()
        mainMenu.addItem(fileItem)
        let fileMenu = NSMenu(title: "File")
        fileItem.submenu = fileMenu
        fileMenu.addItem(NSMenuItem(title: "New",   action: #selector(newDocument(_:)),   keyEquivalent: "n"))
        fileMenu.addItem(NSMenuItem(title: "Open…", action: #selector(openDocument(_:)),  keyEquivalent: "o"))
        fileMenu.addItem(.separator())
        fileMenu.addItem(NSMenuItem(title: "Save",  action: #selector(saveDocument(_:)),  keyEquivalent: "s"))
        let saveAs = NSMenuItem(title: "Save As…", action: #selector(saveDocumentAs(_:)), keyEquivalent: "S")
        saveAs.keyEquivalentModifierMask = [.command, .shift]
        fileMenu.addItem(saveAs)

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editItem.submenu = editMenu
        editMenu.addItem(NSMenuItem(title: "Undo",       action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo",       action: Selector(("redo:")), keyEquivalent: "Z"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Cut",        action: #selector(NSText.cut(_:)),       keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy",       action: #selector(NSText.copy(_:)),      keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste",      action: #selector(NSText.paste(_:)),     keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenu.addItem(.separator())
        let acItem = NSMenuItem(title: "Autocorrect", action: #selector(toggleAutocorrect(_:)), keyEquivalent: "")
        acItem.state = isAutocorrectEnabled ? .on : .off
        editMenu.addItem(acItem)
        autocorrectMenuItem = acItem

        NSApp.mainMenu = mainMenu
    }

    private func applyAutocorrect(_ enabled: Bool) {
        windowControllers.forEach {
            $0.textView.isAutomaticSpellingCorrectionEnabled = enabled
            $0.textView.isAutomaticQuoteSubstitutionEnabled = enabled
        }
        autocorrectMenuItem.state = enabled ? .on : .off
    }

    @objc func showAbout(_ sender: Any?) {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Notepad++",
            .applicationVersion: "1.3.0",
            .credits: NSAttributedString(
                string: "Minimal native macOS text editor.\nBuilt with Swift and AppKit — no Xcode required.",
                attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)]
            ),
        ])
    }

    @objc func toggleAutocorrect(_ sender: Any?) {
        isAutocorrectEnabled = !isAutocorrectEnabled
        applyAutocorrect(isAutocorrectEnabled)
    }

    // MARK: - File actions

    @objc func newDocument(_ sender: Any?) {
        spawnWindow()
    }

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "txt") ?? .plainText]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        spawnWindow().loadFile(url: url)
    }

    @objc func saveDocument(_ sender: Any?) {
        guard let wc = keyWC else { return }
        if wc.currentFileURL != nil {
            if !wc.saveCurrentFile() {
                let alert = NSAlert()
                alert.messageText = "Could not save file"
                alert.informativeText = "The file could not be saved. Check disk space and permissions."
                alert.alertStyle = .warning
                alert.runModal()
            }
        } else {
            saveDocumentAs(sender)
        }
    }

    @objc func saveDocumentAs(_ sender: Any?) {
        guard let wc = keyWC else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "txt") ?? .plainText]
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = wc.currentFileURL?.lastPathComponent ?? "untitled"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        wc.saveFileAs(url: url)
    }
}
