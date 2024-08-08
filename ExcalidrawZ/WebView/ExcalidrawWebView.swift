//
//  WebView.swift
//  ExcalidrawZ
//
//  Created by Dove Zachary on 2022/12/25.
//

import Foundation
import SwiftUI
import WebKit
import Combine
import OSLog

struct ExcalidrawWebView {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fileState: FileState

    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "WebView")
    
    @Binding var isLoading: Bool
    
    init(isLoading: Binding<Bool>) {
        self._isLoading = isLoading
    }
}

#if os(macOS)
extension ExcalidrawWebView: NSViewRepresentable {
    typealias NSViewType = WKWebView

    func makeNSView(context: Context) -> WKWebView {
        return context.coordinator.webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        print("[ExcalidrawWebView] updateNSView")
        let webView = context.coordinator.webView
        context.coordinator.parent = self
        guard !webView.isLoading else {
            return
        }
        Task {
            try? await context.coordinator.loadFile(from: fileState.currentFile)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

#elseif os(iOS)

#endif