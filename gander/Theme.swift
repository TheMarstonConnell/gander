//
//  Theme.swift
//  gander
//
//  Created by Marston on 2026-01-19.
//

import AppKit

struct Theme {
    let name: String
    let background: NSColor
    let foreground: NSColor
    let gutter: NSColor
    let gutterForeground: NSColor
    let selection: NSColor?

    /// System default theme using macOS system colors
    static let system = Theme(
        name: "System",
        background: .textBackgroundColor,
        foreground: .textColor,
        gutter: .textBackgroundColor,
        gutterForeground: .secondaryLabelColor,
        selection: nil
    )
}

// MARK: - Theme Parser

enum ThemeParser {
    /// Parse a .tmTheme file and extract colors
    static func parse(from url: URL) -> Theme? {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let settings = plist["settings"] as? [[String: Any]],
              let globalSettings = settings.first?["settings"] as? [String: Any] else {
            return nil
        }

        let name = (plist["name"] as? String) ?? url.deletingPathExtension().lastPathComponent

        // Extract colors from global settings
        let background = (globalSettings["background"] as? String).flatMap { NSColor(hex: $0) } ?? .textBackgroundColor
        let foreground = (globalSettings["foreground"] as? String).flatMap { NSColor(hex: $0) } ?? .textColor

        // Gutter colors - use gutter-specific or fall back to main colors
        let gutter = (globalSettings["gutter"] as? String).flatMap { NSColor(hex: $0) }
            ?? (globalSettings["lineHighlight"] as? String).flatMap { NSColor(hex: $0) }
            ?? background
        let gutterForeground = (globalSettings["gutterForeground"] as? String).flatMap { NSColor(hex: $0) }
            ?? foreground.withAlphaComponent(0.5)

        // Selection color
        let selection = (globalSettings["selection"] as? String).flatMap { NSColor(hex: $0) }

        return Theme(
            name: name,
            background: background,
            foreground: foreground,
            gutter: gutter,
            gutterForeground: gutterForeground,
            selection: selection
        )
    }
}

// MARK: - NSColor Hex Extension

extension NSColor {
    /// Initialize NSColor from hex string (#RGB, #RRGGBB, or #RRGGBBAA)
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)

        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        var hexValue: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&hexValue) else {
            return nil
        }

        let r, g, b, a: CGFloat

        switch hexString.count {
        case 3: // RGB (12-bit)
            r = CGFloat((hexValue & 0xF00) >> 8) / 15.0
            g = CGFloat((hexValue & 0x0F0) >> 4) / 15.0
            b = CGFloat(hexValue & 0x00F) / 15.0
            a = 1.0
        case 6: // RRGGBB (24-bit)
            r = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
            g = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
            b = CGFloat(hexValue & 0x0000FF) / 255.0
            a = 1.0
        case 8: // RRGGBBAA (32-bit)
            r = CGFloat((hexValue & 0xFF000000) >> 24) / 255.0
            g = CGFloat((hexValue & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((hexValue & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(hexValue & 0x000000FF) / 255.0
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
