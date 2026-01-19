//
//  ganderApp.swift
//  gander
//
//  Created by Marston on 2026-01-19.
//

import SwiftUI

@main
struct ganderApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: ganderDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
