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

@main
struct TestRunner {
    static func main() {
        testLoadFromNonexistentFile()
        testSaveAndLoad()
        testSaveOverwrites()
        testSaveEmptyString()
        print("\n✅ All ScratchStore tests passed")
    }
}
