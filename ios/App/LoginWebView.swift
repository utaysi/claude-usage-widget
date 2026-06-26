import SwiftUI
import WebKit
import ClaudeUsageCore

/// Shows the shared WKWebView at claude.ai/login so cookies land in the same store.
struct LoginWebView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        webView.load(URLRequest(url: URL(string: ClaudeAPI.loginURL)!))
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

/// Sheet chrome with a Done button the user taps after logging in.
struct LoginSheet: View {
    let webView: WKWebView
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            LoginWebView(webView: webView)
                .ignoresSafeArea()
                .navigationTitle("Log in to Claude")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", action: onDone)
                    }
                }
        }
    }
}
