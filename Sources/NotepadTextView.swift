import AppKit

class NotepadTextView: NSTextView {
    override func insertText(_ string: Any, replacementRange: NSRange) {
        let text = (string as? String) ?? (string as? NSAttributedString)?.string ?? ""
        if text.contains(where: { $0.isWhitespace || $0.isPunctuation }) {
            breakUndoCoalescing()
        }
        super.insertText(string, replacementRange: replacementRange)
    }
}
