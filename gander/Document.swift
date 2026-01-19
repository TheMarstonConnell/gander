//
//  Document.swift
//  gander
//
//  Created by Marston on 2026-01-19.
//

import AppKit
import SwiftUI

@MainActor
class Document: NSDocument {
    var text: String = ""

    nonisolated override class var autosavesInPlace: Bool {
        return false
    }

    override func makeWindowControllers() {
        let contentView = DocumentContentView(document: self)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        window.setFrameAutosaveName("GanderWindow")

        let windowController = NSWindowController(window: window)
        addWindowController(windowController)

        updateWindowTitle()
    }

    override func updateChangeCount(_ change: NSDocument.ChangeType) {
        super.updateChangeCount(change)
        updateWindowTitle()
    }

    override func save(_ sender: Any?) {
        super.save(sender)
        // Update title after save completes
        DispatchQueue.main.async {
            self.updateWindowTitle()
        }
    }

    override func save(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType, completionHandler: @escaping (Error?) -> Void) {
        super.save(to: url, ofType: typeName, for: saveOperation) { error in
            completionHandler(error)
            if error == nil {
                DispatchQueue.main.async {
                    self.updateWindowTitle()
                }
            }
        }
    }

    private func updateWindowTitle() {
        guard let window = windowControllers.first?.window else { return }

        let baseName = fileURL?.lastPathComponent ?? "Untitled"
        if isDocumentEdited {
            window.title = "\(baseName) *"
        } else {
            window.title = baseName
        }
    }

    nonisolated override func data(ofType typeName: String) throws -> Data {
        let textCopy = MainActor.assumeIsolated { self.text }
        guard let data = textCopy.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return data
    }

    nonisolated override func read(from data: Data, ofType typeName: String) throws {
        guard let string = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        MainActor.assumeIsolated { self.text = string }
    }
}

struct DocumentContentView: View {
    @State private var text: String
    let document: Document
    var themeManager = ThemeManager.shared

    init(document: Document) {
        self.document = document
        self._text = State(initialValue: document.text)
    }

    var body: some View {
        PaddedTextEditor(text: $text, theme: themeManager.currentTheme)
            .onChange(of: text) { _, newValue in
                if document.text != newValue {
                    document.text = newValue
                    document.updateChangeCount(.changeDone)
                }
            }
    }
}
