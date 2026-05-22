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
