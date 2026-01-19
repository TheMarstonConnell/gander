//
//  ganderApp.swift
//  gander
//
//  Created by Marston on 2026-01-19.
//

import AppKit

class GanderDocumentController: NSDocumentController {
    override func openDocument(_ sender: Any?) {
        // Check if current document is empty and untitled
        if let currentDoc = currentDocument as? Document,
           currentDoc.fileURL == nil,
           currentDoc.text.isEmpty || currentDoc.text == "Hello, world!" {
            // Use open panel and replace current document
            let openPanel = NSOpenPanel()
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseDirectories = false
            openPanel.canChooseFiles = true

            openPanel.begin { [weak self] response in
                if response == .OK, let url = openPanel.url {
                    // Close the empty document
                    currentDoc.close()
                    // Open the selected file
                    self?.openDocument(withContentsOf: url, display: true) { _, _, _ in }
                }
            }
        } else {
            // Default behavior
            super.openDocument(sender)
        }
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let documentController = GanderDocumentController()

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        _ = delegate.documentController // Initialize our custom controller
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenus()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        NSDocumentController.shared.newDocument(nil)
        return true
    }

    private func setupMenus() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Gander", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Gander", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "New", action: #selector(NSDocumentController.newDocument(_:)), keyEquivalent: "n")
        fileMenu.addItem(withTitle: "Open...", action: #selector(NSDocumentController.openDocument(_:)), keyEquivalent: "o")
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Save", action: #selector(NSDocument.save(_:)), keyEquivalent: "s")
        fileMenu.addItem(withTitle: "Save As...", action: #selector(NSDocument.saveAs(_:)), keyEquivalent: "S")
        fileMenu.addItem(withTitle: "Revert to Saved", action: #selector(NSDocument.revertToSaved(_:)), keyEquivalent: "")
        fileMenu.addItem(NSMenuItem.separator())

        let openConfigItem = NSMenuItem(title: "Open Config...", action: #selector(openConfig), keyEquivalent: ",")
        openConfigItem.target = self
        fileMenu.addItem(openConfigItem)

        let reloadConfigItem = NSMenuItem(title: "Reload Config", action: #selector(reloadConfig), keyEquivalent: "r")
        reloadConfigItem.keyEquivalentModifierMask = [.command, .shift]
        reloadConfigItem.target = self
        fileMenu.addItem(reloadConfigItem)

        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Edit menu
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
        NSApp.windowsMenu = windowMenu
    }

    @objc func openConfig() {
        ThemeManager.shared.openConfigInFinder()
    }

    @objc func reloadConfig() {
        ThemeManager.shared.reloadTheme()
    }
}
