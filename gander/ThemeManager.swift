//
//  ThemeManager.swift
//  gander
//
//  Created by Marston on 2026-01-19.
//

import Foundation

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    private let configDirectoryURL: URL
    private let configFileURL: URL

    private(set) var currentTheme: Theme = .system

    func reloadTheme() {
        currentTheme = loadTheme() ?? .system
    }

    private init() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        configDirectoryURL = homeDirectory.appendingPathComponent(".gander")
        configFileURL = configDirectoryURL.appendingPathComponent("config")
        reloadTheme()
    }

    /// Ensures the config file exists, creating it with example content if missing
    func ensureConfigFileExists() {
        let fileManager = FileManager.default

        // Create directory if needed
        if !fileManager.fileExists(atPath: configDirectoryURL.path) {
            try? fileManager.createDirectory(at: configDirectoryURL, withIntermediateDirectories: true)
        }

        // Create config file with example content if it doesn't exist
        if !fileManager.fileExists(atPath: configFileURL.path) {
            let availableThemes = listAvailableThemes().joined(separator: ", ")
            let exampleContent = """
            # Gander Configuration
            # Changes take effect on next app launch.
            #
            # Available themes: \(availableThemes)
            #
            # theme=Catppuccin Mocha
            """
            try? exampleContent.write(to: configFileURL, atomically: true, encoding: .utf8)
        }
    }

    /// Returns the URL to the config file
    func getConfigFileURL() -> URL {
        ensureConfigFileExists()
        return configFileURL
    }

    /// Lists all available theme names from the bundle
    func listAvailableThemes() -> [String] {
        guard let resourceURL = Bundle.main.resourceURL,
              let contents = try? FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil) else {
            return []
        }

        return contents
            .filter { $0.pathExtension == "tmTheme" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }

    // MARK: - Private Methods

    private func loadTheme() -> Theme? {
        guard let themeName = parseConfigForTheme() else {
            return nil
        }

        return loadTheme(named: themeName)
    }

    private func parseConfigForTheme() -> String? {
        guard let content = try? String(contentsOf: configFileURL, encoding: .utf8) else {
            return nil
        }

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Parse key=value
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)

                if key == "theme" && !value.isEmpty {
                    return value
                }
            }
        }

        return nil
    }

    private func loadTheme(named name: String) -> Theme? {
        guard let themeURL = Bundle.main.url(forResource: name, withExtension: "tmTheme") else {
            return nil
        }

        return ThemeParser.parse(from: themeURL)
    }
}
