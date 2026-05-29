import AppKit

class NotepadWindowController: NSWindowController, NSWindowDelegate, NSTextViewDelegate {
    private(set) var textView: NotepadTextView!
    var currentFileURL: URL?
    private(set) var hasUnsavedChanges = false

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Notepad++"
        window.minSize = NSSize(width: 400, height: 300)
        window.center()
        self.init(window: window)
        window.delegate = self
        setupTextView()
    }

    private func setupTextView() {
        guard let contentView = window?.contentView else { return }

        let scrollView = NSScrollView(frame: contentView.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder

        let contentSize = scrollView.contentSize
        let textView = NotepadTextView(frame: NSRect(origin: .zero, size: contentSize))
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(
            width: contentSize.width, height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true

        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isContinuousSpellCheckingEnabled = true
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.textContainer?.lineFragmentPadding = 0
        textView.delegate = self

        scrollView.documentView = textView
        contentView.addSubview(scrollView)
        self.textView = textView
    }

    // MARK: - Scratchpad

    func loadScratchpad() {
        currentFileURL = nil
        textView.string = ScratchStore.shared.load()
        window?.title = "Notepad++"
        window?.isDocumentEdited = false
        hasUnsavedChanges = false
    }

    func saveScratchpad() {
        if currentFileURL == nil {
            ScratchStore.shared.save(textView.string)
        }
    }

    // MARK: - File Mode

    func loadFile(url: URL) {
        // Save scratchpad before switching to file mode
        if currentFileURL == nil {
            ScratchStore.shared.save(textView.string)
        }
        let text: String
        do {
            text = try String(contentsOf: url, encoding: .utf8)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not open file"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
            return
        }
        currentFileURL = url
        textView.string = text
        window?.title = url.lastPathComponent
        window?.isDocumentEdited = false
        hasUnsavedChanges = false
    }

    @discardableResult
    func saveCurrentFile() -> Bool {
        guard let url = currentFileURL else { return false }
        do {
            try textView.string.write(to: url, atomically: true, encoding: .utf8)
            window?.isDocumentEdited = false
            hasUnsavedChanges = false
            return true
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not save \"\(url.lastPathComponent)\""
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
            return false
        }
    }

    func saveFileAs(url: URL) {
        do {
            try textView.string.write(to: url, atomically: true, encoding: .utf8)
            currentFileURL = url
            window?.title = url.lastPathComponent
            window?.isDocumentEdited = false
            hasUnsavedChanges = false
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not save file"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }

    // MARK: - Unsaved changes

    enum UnsavedChangesAction { case save, discard, cancel }

    func promptForUnsavedChanges() -> UnsavedChangesAction {
        guard hasUnsavedChanges else { return .discard }
        let filename = currentFileURL?.lastPathComponent ?? "scratch"
        let alert = NSAlert()
        alert.messageText = "Save changes to \"\(filename)\"?"
        alert.informativeText = "Your changes will be lost if you don't save them."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")
        switch alert.runModal() {
        case .alertFirstButtonReturn:  return .save
        case .alertSecondButtonReturn: return .discard
        default:                       return .cancel
        }
    }

    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if currentFileURL == nil {
            ScratchStore.shared.save(textView.string)
            return true
        }
        switch promptForUnsavedChanges() {
        case .save:    return saveCurrentFile()
        case .discard: return true
        case .cancel:  return false
        }
    }

    // MARK: - NSTextViewDelegate

    func textDidChange(_ notification: Notification) {
        hasUnsavedChanges = true
        if currentFileURL != nil {
            window?.isDocumentEdited = true
        }
    }
}
