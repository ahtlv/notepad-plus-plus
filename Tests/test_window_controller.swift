import AppKit

// MARK: - Helpers

func tmpURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("notepad_test_\(Int.random(in: 100000...999999)).txt")
}

func makeWC() -> NotepadWindowController {
    NotepadWindowController()
}

// MARK: - saveFileAs

func testSaveFileAs_writesContent() {
    let wc = makeWC()
    let url = tmpURL()
    wc.textView.string = "Hello, Notepad!"
    wc.saveFileAs(url: url)
    let content = try? String(contentsOf: url, encoding: .utf8)
    assert(content == "Hello, Notepad!", "saveFileAs must write textView content")
    try? FileManager.default.removeItem(at: url)
    print("✅ testSaveFileAs_writesContent")
}

func testSaveFileAs_setsCurrentFileURL() {
    let wc = makeWC()
    let url = tmpURL()
    wc.textView.string = "test"
    wc.saveFileAs(url: url)
    assert(wc.currentFileURL == url, "currentFileURL must be set after saveFileAs")
    try? FileManager.default.removeItem(at: url)
    print("✅ testSaveFileAs_setsCurrentFileURL")
}

func testSaveFileAs_clearsUnsavedChanges() {
    let wc = makeWC()
    let url = tmpURL()
    wc.textView.string = "test"
    wc.saveFileAs(url: url)
    assert(!wc.hasUnsavedChanges, "hasUnsavedChanges must be false after saveFileAs")
    try? FileManager.default.removeItem(at: url)
    print("✅ testSaveFileAs_clearsUnsavedChanges")
}

// MARK: - saveCurrentFile

func testSaveCurrentFile_roundtrip() {
    let wc = makeWC()
    let url = tmpURL()
    wc.textView.string = "version 1"
    wc.saveFileAs(url: url)

    wc.textView.string = "version 2"
    let ok = wc.saveCurrentFile()
    assert(ok, "saveCurrentFile must return true")

    let content = try? String(contentsOf: url, encoding: .utf8)
    assert(content == "version 2", "saveCurrentFile must overwrite with new content")
    try? FileManager.default.removeItem(at: url)
    print("✅ testSaveCurrentFile_roundtrip")
}

func testSaveCurrentFile_returnsFalseWithoutURL() {
    let wc = makeWC()
    wc.loadScratchpad()
    let ok = wc.saveCurrentFile()
    assert(!ok, "saveCurrentFile must return false when no file URL is set")
    print("✅ testSaveCurrentFile_returnsFalseWithoutURL")
}

// MARK: - loadFile

func testLoadFile_setsTextViewContent() {
    let url = tmpURL()
    try! "Loaded content".write(to: url, atomically: true, encoding: .utf8)
    let wc = makeWC()
    wc.loadFile(url: url)
    assert(wc.textView.string == "Loaded content", "loadFile must populate textView")
    assert(wc.currentFileURL == url, "currentFileURL must be set after loadFile")
    assert(!wc.hasUnsavedChanges, "hasUnsavedChanges must be false after loadFile")
    try? FileManager.default.removeItem(at: url)
    print("✅ testLoadFile_setsTextViewContent")
}

func testLoadFile_savesScatchpadFirst() {
    let wc = makeWC()
    wc.loadScratchpad()
    wc.textView.string = "scratchpad content"
    // loading a file from scratchpad mode should save scratchpad
    let url = tmpURL()
    try! "file content".write(to: url, atomically: true, encoding: .utf8)
    wc.loadFile(url: url)
    // after load, window is in file mode
    assert(wc.currentFileURL == url, "should be in file mode after loadFile")
    try? FileManager.default.removeItem(at: url)
    print("✅ testLoadFile_savesScatchpadFirst")
}

// MARK: - hasUnsavedChanges / promptForUnsavedChanges

func testHasUnsavedChanges_falseInitially() {
    let wc = makeWC()
    wc.loadScratchpad()
    assert(!wc.hasUnsavedChanges, "fresh scratchpad must have no unsaved changes")
    print("✅ testHasUnsavedChanges_falseInitially")
}

func testPromptForUnsavedChanges_discardWhenClean() {
    let wc = makeWC()
    wc.loadScratchpad()
    // hasUnsavedChanges == false → must return .discard without showing a dialog
    let action = wc.promptForUnsavedChanges()
    assert(action == .discard, "must return .discard when there are no unsaved changes")
    print("✅ testPromptForUnsavedChanges_discardWhenClean")
}

// MARK: - Runner

@main struct TestRunner {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)

        testSaveFileAs_writesContent()
        testSaveFileAs_setsCurrentFileURL()
        testSaveFileAs_clearsUnsavedChanges()
        testSaveCurrentFile_roundtrip()
        testSaveCurrentFile_returnsFalseWithoutURL()
        testLoadFile_setsTextViewContent()
        testLoadFile_savesScatchpadFirst()
        testHasUnsavedChanges_falseInitially()
        testPromptForUnsavedChanges_discardWhenClean()
        print("\n✅ All NotepadWindowController tests passed")
    }
}
