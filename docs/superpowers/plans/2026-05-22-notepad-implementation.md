# Notepad Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Собрать нативную macOS-апку на Swift + AppKit — персистентный скрэтчпэд с возможностью открывать и сохранять .txt файлы.

**Architecture:** Три Swift-файла: `AppDelegate` (жизненный цикл + меню), `NotepadWindowController` (окно + NSTextView, оба режима), `ScratchStore` (чтение/запись скрэтчпэда). Компилируется через `swiftc` без Xcode IDE. Shell-скрипт `build.sh` упаковывает бинарник в `.app` bundle.

**Tech Stack:** Swift 6, AppKit, Foundation, UniformTypeIdentifiers. Без SPM, без Xcode, без сторонних зависимостей.

---

### Task 1: Project skeleton

**Files:**
- Create: `Sources/` (пусто)
- Create: `Resources/Info.plist`
- Create: `Tests/` (пусто)
- Create: `build/` (пусто, в .gitignore)
- Create: `.gitignore`
- Create: `build.sh`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p /Users/anatoli/Work/notepad++/Sources
mkdir -p /Users/anatoli/Work/notepad++/Resources
mkdir -p /Users/anatoli/Work/notepad++/Tests
mkdir -p /Users/anatoli/Work/notepad++/build
```

- [ ] **Step 2: Create .gitignore**

Create `/Users/anatoli/Work/notepad++/.gitignore`:
```
build/
*.app
.DS_Store
```

- [ ] **Step 3: Create Resources/Info.plist**

Create `/Users/anatoli/Work/notepad++/Resources/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Notepad</string>
    <key>CFBundleIdentifier</key>
    <string>com.anatoli.notepad</string>
    <key>CFBundleName</key>
    <string>Notepad</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeExtensions</key>
            <array><string>txt</string></array>
            <key>CFBundleTypeName</key>
            <string>Plain Text</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
        </dict>
    </array>
</dict>
</plist>
```

- [ ] **Step 4: Create build.sh**

Create `/Users/anatoli/Work/notepad++/build.sh`:
```bash
#!/bin/bash
set -e

APP_NAME="Notepad"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app/Contents"

echo "🔨 Building $APP_NAME..."

rm -rf "$BUILD_DIR/$APP_NAME.app"
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"

swiftc Sources/*.swift \
    -o "$APP_DIR/MacOS/$APP_NAME" \
    -framework AppKit \
    -framework Foundation

cp Resources/Info.plist "$APP_DIR/Info.plist"

echo "✅ Built: $BUILD_DIR/$APP_NAME.app"
echo "   To install: cp -r $BUILD_DIR/$APP_NAME.app /Applications/"
```

- [ ] **Step 5: Make build.sh executable**

```bash
chmod +x /Users/anatoli/Work/notepad++/build.sh
```

- [ ] **Step 6: Commit**

```bash
cd /Users/anatoli/Work/notepad++
git add .gitignore Resources/Info.plist build.sh
git commit -m "feat: project skeleton — Info.plist, build.sh, directory structure"
```

---

### Task 2: ScratchStore (TDD)

**Files:**
- Create: `Tests/test_scratch_store.swift`
- Create: `Sources/ScratchStore.swift`

- [ ] **Step 1: Write the failing test first**

Create `/Users/anatoli/Work/notepad++/Tests/test_scratch_store.swift`:
```swift
import Foundation

func testLoadFromNonexistentFile() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("notepad_test_\(Int.random(in: 10000...99999)).txt")
    let store = ScratchStore(url: url)
    assert(store.load() == "", "Non-existent file should return empty string")
    print("✅ testLoadFromNonexistentFile")
}

func testSaveAndLoad() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("notepad_test_\(Int.random(in: 10000...99999)).txt")
    let store = ScratchStore(url: url)
    store.save("Hello, Notepad!")
    assert(store.load() == "Hello, Notepad!", "Loaded text must match saved text")
    try? FileManager.default.removeItem(at: url)
    print("✅ testSaveAndLoad")
}

func testSaveOverwrites() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("notepad_test_\(Int.random(in: 10000...99999)).txt")
    let store = ScratchStore(url: url)
    store.save("first version")
    store.save("second version")
    assert(store.load() == "second version", "Second save must overwrite first")
    try? FileManager.default.removeItem(at: url)
    print("✅ testSaveOverwrites")
}

func testSaveEmptyString() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("notepad_test_\(Int.random(in: 10000...99999)).txt")
    let store = ScratchStore(url: url)
    store.save("something")
    store.save("")
    assert(store.load() == "", "Saving empty string must return empty on load")
    try? FileManager.default.removeItem(at: url)
    print("✅ testSaveEmptyString")
}

testLoadFromNonexistentFile()
testSaveAndLoad()
testSaveOverwrites()
testSaveEmptyString()
print("\n✅ All ScratchStore tests passed")
```

- [ ] **Step 2: Run test — expect compile failure**

```bash
cd /Users/anatoli/Work/notepad++
swiftc Tests/test_scratch_store.swift -framework Foundation -o build/test_scratch 2>&1
```

Expected: `error: cannot find type 'ScratchStore' in scope`

- [ ] **Step 3: Implement ScratchStore**

Create `/Users/anatoli/Work/notepad++/Sources/ScratchStore.swift`:
```swift
import Foundation

struct ScratchStore {
    let url: URL

    static let shared: ScratchStore = {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        )[0]
        let dir = appSupport.appendingPathComponent("Notepad")
        try? FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true, attributes: nil
        )
        return ScratchStore(url: dir.appendingPathComponent("scratch.txt"))
    }()

    func load() -> String {
        (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    func save(_ text: String) {
        try? text.write(to: url, atomically: true, encoding: .utf8)
    }
}
```

- [ ] **Step 4: Run tests — expect all pass**

```bash
cd /Users/anatoli/Work/notepad++
swiftc Sources/ScratchStore.swift Tests/test_scratch_store.swift \
    -framework Foundation \
    -o build/test_scratch && ./build/test_scratch
```

Expected output:
```
✅ testLoadFromNonexistentFile
✅ testSaveAndLoad
✅ testSaveOverwrites
✅ testSaveEmptyString

✅ All ScratchStore tests passed
```

- [ ] **Step 5: Commit**

```bash
cd /Users/anatoli/Work/notepad++
git add Sources/ScratchStore.swift Tests/test_scratch_store.swift
git commit -m "feat: ScratchStore — scratchpad persistence with tests"
```

---

### Task 3: NotepadWindowController (window + NSTextView)

**Files:**
- Create: `Sources/NotepadWindowController.swift`
- Create: `Sources/main.swift` (временный, для проверки окна)

- [ ] **Step 1: Create NotepadWindowController.swift**

Create `/Users/anatoli/Work/notepad++/Sources/NotepadWindowController.swift`:
```swift
import AppKit

class NotepadWindowController: NSWindowController, NSWindowDelegate, NSTextViewDelegate {
    private(set) var textView: NSTextView!
    var currentFileURL: URL?
    private(set) var hasUnsavedChanges = false

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Notepad"
        window.minSize = NSSize(width: 400, height: 300)
        window.center()
        window.setFrameAutosaveName("NotepadWindow")
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
        let textView = NSTextView(frame: NSRect(origin: .zero, size: contentSize))
        textView.minSize = NSSize(width: 0, height: contentSize.height)
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
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = true
        textView.isContinuousSpellCheckingEnabled = true
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.delegate = self

        scrollView.documentView = textView
        contentView.addSubview(scrollView)
        self.textView = textView
    }

    // MARK: - Scratchpad

    func loadScratchpad() {
        currentFileURL = nil
        textView.string = ScratchStore.shared.load()
        window?.title = "Notepad"
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
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return }
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
        } catch {}
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
        saveScratchpad()
        guard currentFileURL != nil else { return true }
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
```

- [ ] **Step 2: Create temporary main.swift**

Create `/Users/anatoli/Work/notepad++/Sources/main.swift`:
```swift
import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.regular)

class TempDelegate: NSObject, NSApplicationDelegate {
    var wc: NotepadWindowController!
    func applicationDidFinishLaunching(_ n: Notification) {
        wc = NotepadWindowController()
        wc.showWindow(nil)
        wc.textView.string = "Window works! Autocorrect active. isRichText=false (paste rich text — it pastes plain)."
        app.activate(ignoringOtherApps: true)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }
}

let del = TempDelegate()
app.delegate = del
app.run()
```

- [ ] **Step 3: Build and run**

```bash
cd /Users/anatoli/Work/notepad++
./build.sh && open build/Notepad.app
```

Expected: окно открывается с текстом-инструкцией, можно скроллить.

- [ ] **Step 4: Проверить NSTextView**

- Напечатать слово с опечаткой → подчёркивается красным
- Вставить rich text из браузера (`⌘V`) → вставляется plain text без форматирования
- Окно ресайзится — текст перерпрётывается по ширине

- [ ] **Step 5: Commit**

```bash
cd /Users/anatoli/Work/notepad++
git add Sources/NotepadWindowController.swift Sources/main.swift
git commit -m "feat: NotepadWindowController — NSWindow + NSTextView, autocorrect, plain text"
```

---

### Task 4: AppDelegate + main menu

**Files:**
- Create: `Sources/AppDelegate.swift`
- Modify: `Sources/main.swift` (заменить TempDelegate на реальный AppDelegate)

- [ ] **Step 1: Create AppDelegate.swift**

Create `/Users/anatoli/Work/notepad++/Sources/AppDelegate.swift`:
```swift
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
            wc.saveCurrentFile()
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
```

- [ ] **Step 2: Replace main.swift**

Overwrite `/Users/anatoli/Work/notepad++/Sources/main.swift`:
```swift
import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

- [ ] **Step 3: Build and run**

```bash
cd /Users/anatoli/Work/notepad++
./build.sh && open build/Notepad.app
```

Expected: запускается, в menu bar видны "Notepad" + "File" + "Edit".

- [ ] **Step 4: Проверить меню**

- `⌘N` → без краша (скрэтчпэд перезагружается)
- `⌘O` → открывается file picker, фильтрует .txt
- `⌘S` → открывается NSSavePanel (режим скрэтчпэда)
- `⌘⇧S` → открывается NSSavePanel
- `⌘Z` / `⌘⇧Z` → undo/redo в тексте работают
- `⌘X` / `⌘C` / `⌘V` / `⌘A` → cut/copy/paste/select all работают
- `⌘Q` → приложение завершается

- [ ] **Step 5: Commit**

```bash
cd /Users/anatoli/Work/notepad++
git add Sources/AppDelegate.swift Sources/main.swift
git commit -m "feat: AppDelegate — app lifecycle, File + Edit menus, all keyboard shortcuts"
```

---

### Task 5: Scratchpad persistence (end-to-end)

Ручная проверка что auto-save/load работает корректно.

- [ ] **Step 1: Build и запустить**

```bash
cd /Users/anatoli/Work/notepad++
./build.sh && open build/Notepad.app
```

- [ ] **Step 2: Напечатать текст и выйти**

Ввести в поле: `scratchpad persistence test 123`, закрыть окно (`⌘Q`).

- [ ] **Step 3: Перезапустить и проверить**

```bash
open build/Notepad.app
```

Expected: текст `scratchpad persistence test 123` присутствует при запуске.

- [ ] **Step 4: Проверить файл напрямую**

```bash
cat ~/Library/Application\ Support/Notepad/scratch.txt
```

Expected: `scratchpad persistence test 123`

- [ ] **Step 5: Проверить что переключение в file mode сохраняет скрэтчпэд**

- В работающем приложении добавить текст: ` — with more text`
- Открыть любой .txt через `⌘O` (создать: `echo "file content" > /tmp/np_test.txt`)
- Закрыть приложение `⌘Q`
- Перезапустить → нажать `⌘N`
- Expected: скрэтчпэд содержит `scratchpad persistence test 123 — with more text`

```bash
rm /tmp/np_test.txt
```

- [ ] **Step 6: Commit**

```bash
cd /Users/anatoli/Work/notepad++
git commit --allow-empty -m "test: scratchpad persistence verified end-to-end"
```

---

### Task 6: File mode — open, save, save as (end-to-end)

- [ ] **Step 1: Подготовить тестовый файл**

```bash
echo "Hello from test file" > /tmp/np_filemode_test.txt
```

- [ ] **Step 2: Открыть файл через ⌘O**

- Запустить приложение, нажать `⌘O`
- Открыть `/tmp/np_filemode_test.txt`
- Expected: в тексте "Hello from test file", title bar показывает `np_filemode_test.txt`

- [ ] **Step 3: Редактировать и сохранить через ⌘S**

- Добавить текст: ` — edited`
- Нажать `⌘S`
- Expected: панель не открывается (сохраняет напрямую), точка на кнопке закрытия исчезает

```bash
cat /tmp/np_filemode_test.txt
```

Expected: `Hello from test file — edited`

- [ ] **Step 4: Save As через ⌘⇧S**

- Нажать `⌘⇧S`, сохранить как `/tmp/np_filemode_copy.txt`
- Expected: title bar обновляется до `np_filemode_copy.txt`

```bash
cat /tmp/np_filemode_copy.txt
```

Expected: `Hello from test file — edited`

- [ ] **Step 5: Вернуться в скрэтчпэд через ⌘N**

- Нажать `⌘N`
- Expected: title bar → "Notepad", в тексте прежнее содержимое скрэтчпэда

- [ ] **Step 6: Cleanup**

```bash
rm /tmp/np_filemode_test.txt /tmp/np_filemode_copy.txt
```

- [ ] **Step 7: Commit**

```bash
cd /Users/anatoli/Work/notepad++
git commit --allow-empty -m "test: file mode (open/save/save as) verified end-to-end"
```

---

### Task 7: Unsaved changes alerts

- [ ] **Step 1: Создать тестовый файл**

```bash
echo "original content" > /tmp/np_unsaved_test.txt
```

- [ ] **Step 2: Проверить алерт при ⌘N**

- Открыть файл через `⌘O`
- Отредактировать (добавить что-нибудь)
- Нажать `⌘N`
- Expected: алерт "Save changes to "np_unsaved_test.txt"?" с кнопками Save / Don't Save / Cancel
- Нажать **Cancel** → алерт закрывается, file mode остаётся с правками
- Нажать `⌘N` снова → алерт снова
- Нажать **Don't Save** → скрэтчпэд загружается, правки удалены

- [ ] **Step 3: Проверить алерт при закрытии окна**

- Открыть файл через `⌘O`, добавить текст
- Нажать `⌘W`
- Expected: алерт Save / Don't Save / Cancel
- Нажать **Save** → файл сохранён, окно закрывается, приложение выходит

- [ ] **Step 4: Проверить что скрэтчпэд закрывается без алерта**

- Запустить приложение → скрэтчпэд
- Ввести текст
- Нажать `⌘W`
- Expected: окно закрывается немедленно (алерта нет — скрэтчпэд всегда auto-saves)

- [ ] **Step 5: Cleanup**

```bash
rm -f /tmp/np_unsaved_test.txt
```

- [ ] **Step 6: Commit**

```bash
cd /Users/anatoli/Work/notepad++
git commit --allow-empty -m "test: unsaved changes alerts verified"
```

---

### Task 8: Build .app bundle + install

- [ ] **Step 1: Final build**

```bash
cd /Users/anatoli/Work/notepad++
./build.sh
```

Expected:
```
🔨 Building Notepad...
✅ Built: build/Notepad.app
   To install: cp -r build/Notepad.app /Applications/
```

- [ ] **Step 2: Проверить структуру .app**

```bash
find build/Notepad.app -type f
```

Expected:
```
build/Notepad.app/Contents/MacOS/Notepad
build/Notepad.app/Contents/Info.plist
```

- [ ] **Step 3: Проверить архитектуру бинарника**

```bash
file build/Notepad.app/Contents/MacOS/Notepad
```

Expected: `... Mach-O 64-bit executable arm64`

- [ ] **Step 4: Установить в /Applications/**

```bash
cp -r build/Notepad.app /Applications/Notepad.app
```

- [ ] **Step 5: Первый запуск — обойти Gatekeeper если нужно**

```bash
open /Applications/Notepad.app
```

Если macOS заблокировал ("cannot be opened because it is from an unidentified developer"):
```bash
xattr -d com.apple.quarantine /Applications/Notepad.app
open /Applications/Notepad.app
```

Или: System Settings → Privacy & Security → "Open Anyway".

- [ ] **Step 6: Проверить запуск через Spotlight**

- `⌘Space`, ввести "Notepad", нажать Enter
- Expected: приложение открывается, скрэтчпэд с прежним содержимым

- [ ] **Step 7: Final commit**

```bash
cd /Users/anatoli/Work/notepad++
git add -A
git commit -m "feat: complete Notepad.app — native macOS notepad, Apple Silicon, scratchpad + file mode"
```
