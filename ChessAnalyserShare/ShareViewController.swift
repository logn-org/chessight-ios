import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        extractSharedContent()
    }

    private func extractSharedContent() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            done()
            return
        }

        for item in items {
            guard let attachments = item.attachments else { continue }

            for attachment in attachments {
                // Try plain text first (PGN, share message, etc.)
                if attachment.hasItemConformingToTypeIdentifier("public.plain-text") {
                    attachment.loadItem(forTypeIdentifier: "public.plain-text") { [weak self] data, _ in
                        if let text = data as? String {
                            self?.openMainApp(with: text)
                        } else {
                            self?.done()
                        }
                    }
                    return
                }

                // Try URL
                if attachment.hasItemConformingToTypeIdentifier("public.url") {
                    attachment.loadItem(forTypeIdentifier: "public.url") { [weak self] data, _ in
                        if let url = data as? URL {
                            self?.openMainApp(with: url.absoluteString)
                        } else if let urlData = data as? Data, let urlString = String(data: urlData, encoding: .utf8) {
                            self?.openMainApp(with: urlString)
                        } else {
                            self?.done()
                        }
                    }
                    return
                }

                // Try generic text
                if attachment.hasItemConformingToTypeIdentifier("public.text") {
                    attachment.loadItem(forTypeIdentifier: "public.text") { [weak self] data, _ in
                        if let text = data as? String {
                            self?.openMainApp(with: text)
                        } else {
                            self?.done()
                        }
                    }
                    return
                }
            }
        }

        done()
    }

    private func openMainApp(with content: String) {
        guard let encoded = content.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "chessight://share?content=\(encoded)") else {
            done()
            return
        }

        // Open the main app via URL scheme
        // Share extensions can't open URLs directly, so we use openURL via the responder chain
        DispatchQueue.main.async { [weak self] in
            self?.openURL(url)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.done()
            }
        }
    }

    @objc private func openURL(_ url: URL) {
        // Walk up the responder chain to find UIApplication
        var responder: UIResponder? = self
        while let r = responder {
            if let app = r as? UIApplication {
                app.open(url)
                return
            }
            responder = r.next
        }

        // Fallback: use selector-based approach
        let selector = sel_registerName("openURL:")
        var current: UIResponder? = self
        while let r = current {
            if r.responds(to: selector) {
                r.perform(selector, with: url)
                return
            }
            current = r.next
        }
    }

    private func done() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
