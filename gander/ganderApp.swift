//
//  ganderApp.swift
//  gander
//
//  Created by Marston on 2026-01-19.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Delay check to allow new document windows to open
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if NSApp.windows.filter({ $0.isVisible }).isEmpty {
                NSApp.terminate(nil)
            }
        }
        return false
    }
}

struct SaveCommand: Commands {
    @FocusedValue(\.saveAction) var saveAction

    var body: some Commands {
        CommandGroup(replacing: .saveItem) {
            Button("Save") {
                saveAction?.action()
            }
            .keyboardShortcut("s", modifiers: .command)
        }
    }
}

struct ConfigCommands: Commands {
    @Environment(\.openDocument) private var openDocument

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Divider()
            Button("Open Config...") {
                Task {
                    let configURL = ThemeManager.shared.getConfigFileURL()
                    try? await openDocument(at: configURL)
                }
            }
            .keyboardShortcut(",", modifiers: .command)

            Button("Reload Config") {
                ThemeManager.shared.reloadTheme()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }
    }
}

@main
struct ganderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private var themeManager = ThemeManager.shared

    var body: some Scene {
        DocumentGroup(newDocument: ganderDocument()) { file in
            ContentView(document: file.$document, themeManager: themeManager)
        }
        .commands {
            SaveCommand()
            ConfigCommands()
        }
    }
}
