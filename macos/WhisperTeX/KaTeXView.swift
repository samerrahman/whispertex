import SwiftUI
import WebKit

struct KaTeXView: NSViewRepresentable {
    let latex: String
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let cleanLatex = latex
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: "")

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css">
          <script src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js"></script>
          <style>
            body {
              margin: 0;
              padding: 12px;
              background: transparent;
              color: #e2e8f0;
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
              display: flex;
              align-items: center;
              justify-content: center;
              min-height: 60px;
              overflow-x: auto;
            }
            #math {
              font-size: 1.35em;
              text-align: center;
            }
          </style>
        </head>
        <body>
          <div id="math"></div>
          <script>
            try {
              katex.render("\(cleanLatex)", document.getElementById('math'), {
                displayMode: true,
                throwOnError: false
              });
            } catch (err) {
              document.getElementById('math').innerText = "\(cleanLatex)";
            }
          </script>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
