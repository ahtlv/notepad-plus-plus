import AppKit
import UniformTypeIdentifiers

class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: NotepadWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        windowController = NotepadWindowController()
        windowController.showWindow(nil)
        windowController.loadScratchpad()
        NSApp.activate(ignoringOtherApps: true)

        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.windowController.saveScratchpad()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowController.saveScratchpad()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // MARK: - Menu

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App menu (первый элемент — имя приложения в menu bar)
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(
            title: "Quit Notepad",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        // File menu
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

        // Edit menu
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

        NSApp.mainMenu = mainMenu
    }

    // MARK: - File actions

    @objc func newDocument(_ sender: Any?) {
        let wc = windowController!
        guard wc.currentFileURL != nil else {
            wc.loadScratchpad()
            return
        }
        switch wc.promptForUnsavedChanges() {
        case .save:
            if !wc.saveCurrentFile() { return }
            wc.loadScratchpad()
        case .discard:
            wc.loadScratchpad()
        case .cancel:
            return
        }
    }

    @objc func openDocument(_ sender: Any?) {
        let wc = windowController!
        if wc.currentFileURL != nil {
            switch wc.promptForUnsavedChanges() {
            case .save:
                if !wc.saveCurrentFile() { return }
            case .discard: break
            case .cancel:  return
            }
        }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        wc.loadFile(url: url)
    }

    @objc func saveDocument(_ sender: Any?) {
        let wc = windowController!
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
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = windowController.currentFileURL?.lastPathComponent ?? "untitled.txt"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        windowController.saveFileAs(url: url)
    }
}
