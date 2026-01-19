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
