//
//  ContentView.swift
//  gander
//
//  Created by Marston on 2026-01-19.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: ganderDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(ganderDocument()))
}
