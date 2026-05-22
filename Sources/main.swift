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
