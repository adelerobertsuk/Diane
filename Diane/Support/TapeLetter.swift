import MessageUI
import SwiftUI
import UIKit

enum TapeLetter {
    static var canSend: Bool {
        MFMailComposeViewController.canSendMail()
    }

    static func pdf(for tape: Tape) -> Data {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let inset: CGFloat = 54
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let when = tape.createdAt.formatted(.dateTime.weekday(.wide).day().month(.wide).year().hour().minute())
        let summary = tape.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let pages = tape.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let showSummary = !summary.isEmpty && summary != pages

        let ink = UIColor(red: 0.17, green: 0.16, blue: 0.14, alpha: 1)
        let muted = UIColor(red: 0.54, green: 0.51, blue: 0.46, alpha: 1)
        let paper = UIColor(red: 0.95, green: 0.93, blue: 0.89, alpha: 1)

        let kicker = [
            NSAttributedString.Key.font: UIFont(name: "Courier", size: 10)
                ?? UIFont.monospacedSystemFont(ofSize: 10, weight: .semibold),
            NSAttributedString.Key.foregroundColor: muted,
            NSAttributedString.Key.kern: 1.4
        ] as [NSAttributedString.Key: Any]

        let title = [
            NSAttributedString.Key.font: UIFont(name: "Courier-Bold", size: 16)
                ?? UIFont.monospacedSystemFont(ofSize: 16, weight: .medium),
            NSAttributedString.Key.foregroundColor: ink
        ] as [NSAttributedString.Key: Any]

        let body = [
            NSAttributedString.Key.font: UIFont(name: "Courier", size: 12)
                ?? UIFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            NSAttributedString.Key.foregroundColor: ink,
            NSAttributedString.Key.paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.lineSpacing = 5
                style.paragraphSpacing = 8
                return style
            }()
        ] as [NSAttributedString.Key: Any]

        var blocks: [(String, [NSAttributedString.Key: Any])] = [
            ("DIANE", kicker),
            (when.uppercased(), kicker),
            (tape.kind.kicker, title)
        ]
        if showSummary {
            blocks += [("SUMMARY", kicker), (summary, body)]
        }
        blocks += [("THE PAGES", kicker), (pages, body)]

        return renderer.pdfData { ctx in
            func newPage() {
                ctx.beginPage()
                paper.setFill()
                UIRectFill(page)
            }

            newPage()
            var y = inset
            let width = page.width - inset * 2

            for (text, attrs) in blocks {
                let rich = NSAttributedString(string: text, attributes: attrs)
                let height = ceil(rich.boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    context: nil
                ).height)

                if y + height > page.height - inset {
                    newPage()
                    y = inset
                }
                rich.draw(with: CGRect(x: inset, y: y, width: width, height: height + 8), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                y += height + 16
            }

            let footer = NSAttributedString(
                string: "Recorded on Diane.",
                attributes: kicker
            )
            if y + 24 > page.height - inset {
                newPage()
                y = inset
            }
            footer.draw(at: CGPoint(x: inset, y: page.height - inset))
        }
    }

    static func bodyHTML(for tape: Tape) -> String {
        let when = tape.createdAt.formatted(.dateTime.weekday(.wide).day().month(.wide).year().hour().minute()).uppercased()
        let summary = tape.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let pages = tape.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let showSummary = !summary.isEmpty && summary != pages
        var lines = [
            "STOP",
            "",
            "DIANE",
            when,
            tape.kind.kicker.uppercased(),
            ""
        ]
        if showSummary {
            lines += ["SUMMARY", escape(summary), ""]
        }
        lines += [
            "THE PAGES",
            escape(pages),
            "",
            "STOP",
            "",
            "Sent with Diane."
        ]
        let text = lines.joined(separator: "<br>")
        return """
        <div style="font-family:'Courier New',Courier,monospace;color:#2C2824;font-size:15px;line-height:1.55;background:#F3EDE4;padding:20px;">
        \(text)
        </div>
        """
    }

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "<br>")
    }
}

struct MailLetterView: UIViewControllerRepresentable {
    let tape: Tape
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = context.coordinator
        mail.setSubject("A tape from Diane")
        mail.setMessageBody(TapeLetter.bodyHTML(for: tape), isHTML: true)
        if let image = UIImage(named: "LetterFolder"), let data = image.pngData() {
            mail.addAttachmentData(data, mimeType: "image/png", fileName: "A tape from Diane.png")
        }
        mail.addAttachmentData(
            TapeLetter.pdf(for: tape),
            mimeType: "application/pdf",
            fileName: "The pages.pdf"
        )
        if let voice = tape.voiceURL, let data = try? Data(contentsOf: voice) {
            let isM4A = voice.pathExtension.lowercased() == "m4a"
            mail.addAttachmentData(
                data,
                mimeType: isM4A ? "audio/mp4" : "audio/x-caf",
                fileName: isM4A ? "The tape.m4a" : "The tape.caf"
            )
        }
        return mail
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var isPresented: Binding<Bool>

        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            isPresented.wrappedValue = false
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
