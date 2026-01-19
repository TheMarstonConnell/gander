//
//  ContentView.swift
//  gander
//
//  Created by Marston on 2026-01-19.
//

import SwiftUI

class LineNumberGutter: NSView {
    weak var textView: NSTextView?
    private let gutterWidth: CGFloat = 40

    var backgroundColor: NSColor = .textBackgroundColor {
        didSet { needsDisplay = true }
    }
    var foregroundColor: NSColor = .secondaryLabelColor {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { true }

    init() {
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: gutterWidth, height: NSView.noIntrinsicMetric)
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let textView = textView,
              let layoutManager = textView.layoutManager else { return }

        let textColor = foregroundColor
        let separatorColor = textColor.withAlphaComponent(0.3)

        // Fill background
        backgroundColor.setFill()
        dirtyRect.fill()

        // Draw separator line
        separatorColor.setStroke()
        let separatorPath = NSBezierPath()
        separatorPath.move(to: NSPoint(x: bounds.width - 0.5, y: dirtyRect.minY))
        separatorPath.line(to: NSPoint(x: bounds.width - 0.5, y: dirtyRect.maxY))
        separatorPath.lineWidth = 1.0
        separatorPath.stroke()

        // Get text attributes
        let font = textView.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let text = textView.string as NSString
        let textInset = textView.textContainerInset
        let visibleRect = textView.visibleRect

        guard text.length > 0 else {
            let lineNumberString = "1"
            let stringSize = lineNumberString.size(withAttributes: attributes)
            let yPosition = textInset.height - visibleRect.origin.y
            let xPosition = gutterWidth - stringSize.width - 8
            lineNumberString.draw(at: NSPoint(x: xPosition, y: yPosition), withAttributes: attributes)
            return
        }

        var lineNumber = 1
        var index = 0

        while index < text.length {
            let lineRange = text.lineRange(for: NSRange(location: index, length: 0))
            let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)

            if glyphRange.location != NSNotFound && glyphRange.length > 0 {
                let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphRange.location, effectiveRange: nil)
                let yInGutter = lineRect.origin.y + textInset.height - visibleRect.origin.y

                if yInGutter + lineRect.height >= dirtyRect.minY && yInGutter <= dirtyRect.maxY {
                    let lineNumberString = "\(lineNumber)"
                    let stringSize = lineNumberString.size(withAttributes: attributes)
                    let yDrawPosition = yInGutter + (lineRect.height - stringSize.height) / 2
                    let xPosition = gutterWidth - stringSize.width - 8

                    lineNumberString.draw(at: NSPoint(x: xPosition, y: yDrawPosition), withAttributes: attributes)
                }
            }

            lineNumber += 1
            index = NSMaxRange(lineRange)
            if index == lineRange.location { break }
        }
    }
}

class TextEditorContainer: NSView {
    let scrollView: NSScrollView
    let textView: NSTextView
    let gutter: LineNumberGutter

    override var isFlipped: Bool { true }

    var backgroundColor: NSColor = .textBackgroundColor {
        didSet {
            textView.backgroundColor = backgroundColor
            scrollView.backgroundColor = backgroundColor
        }
    }

    var foregroundColor: NSColor = .textColor {
        didSet {
            textView.textColor = foregroundColor
            textView.insertionPointColor = foregroundColor
        }
    }

    var gutterBackgroundColor: NSColor = .textBackgroundColor {
        didSet {
            gutter.backgroundColor = gutterBackgroundColor
        }
    }

    var gutterForegroundColor: NSColor = .secondaryLabelColor {
        didSet {
            gutter.foregroundColor = gutterForegroundColor
        }
    }

    init() {
        scrollView = NSTextView.scrollableTextView()
        textView = scrollView.documentView as! NSTextView
        gutter = LineNumberGutter()

        super.init(frame: .zero)

        gutter.textView = textView

        addSubview(gutter)
        addSubview(scrollView)

        gutter.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            gutter.leadingAnchor.constraint(equalTo: leadingAnchor),
            gutter.topAnchor.constraint(equalTo: topAnchor),
            gutter.bottomAnchor.constraint(equalTo: bottomAnchor),
            gutter.widthAnchor.constraint(equalToConstant: 40),

            scrollView.leadingAnchor.constraint(equalTo: gutter.trailingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(_ theme: Theme) {
        backgroundColor = theme.background
        foregroundColor = theme.foreground
        gutterBackgroundColor = theme.gutter
        gutterForegroundColor = theme.gutterForeground
    }
}

struct PaddedTextEditor: NSViewRepresentable {
    @Binding var text: String
    let theme: Theme

    func makeNSView(context: Context) -> TextEditorContainer {
        let container = TextEditorContainer()
        let textView = container.textView

        textView.isRichText = false
        textView.allowsUndo = true
        let fontSize = NSFont.systemFontSize
        textView.font = NSFont(name: "JetBrains Mono", size: fontSize)
            ?? NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.delegate = context.coordinator

        // Apply theme colors
        container.applyTheme(theme)

        context.coordinator.gutter = container.gutter

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.viewDidChange(_:)),
            name: NSText.didChangeNotification,
            object: textView
        )

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.viewDidChange(_:)),
            name: NSView.boundsDidChangeNotification,
            object: container.scrollView.contentView
        )

        container.scrollView.contentView.postsBoundsChangedNotifications = true

        return container
    }

    func updateNSView(_ nsView: TextEditorContainer, context: Context) {
        if nsView.textView.string != text {
            nsView.textView.string = text
            context.coordinator.gutter?.needsDisplay = true
        }
        // Update theme when it changes
        nsView.applyTheme(theme)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        weak var gutter: LineNumberGutter?

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
            gutter?.needsDisplay = true
        }

        @objc func viewDidChange(_ notification: Notification) {
            gutter?.needsDisplay = true
        }
    }
}

struct ContentView: View {
    @Binding var document: ganderDocument
    var themeManager: ThemeManager

    var body: some View {
        PaddedTextEditor(text: $document.text, theme: themeManager.currentTheme)
    }
}

#Preview {
    ContentView(document: .constant(ganderDocument()), themeManager: ThemeManager.shared)
}
