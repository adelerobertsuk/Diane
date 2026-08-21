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

    /// Kate's brown envelope, with a soft ink stamp and the owner's name in handwriting on the right.
    static func envelopePNG(addressedTo name: String) -> Data? {
        guard let base = UIImage(named: "LetterFolder") else { return nil }
        let size = base.size
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = base.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let who = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let label = who.isEmpty ? "for you" : who

        let data = renderer.pngData { ctx in
            let cg = ctx.cgContext
            base.draw(in: CGRect(origin: .zero, size: size))

            // Stamp sits on the clear kraft face, right of the taped cassette, above the address lines.
            let stampCenter = CGPoint(x: size.width * 0.70, y: size.height * 0.48)
            let stampRadius = min(size.width, size.height) * 0.125
            let ink = UIColor(red: 0.42, green: 0.18, blue: 0.16, alpha: 0.82)

            cg.saveGState()
            cg.translateBy(x: stampCenter.x, y: stampCenter.y)
            cg.rotate(by: -0.12)

            // Outer ring
            let outer = CGRect(x: -stampRadius, y: -stampRadius, width: stampRadius * 2, height: stampRadius * 2)
            cg.setStrokeColor(ink.cgColor)
            cg.setLineWidth(max(2.2, stampRadius * 0.055))
            cg.strokeEllipse(in: outer)

            // Inner ring
            let inset = stampRadius * 0.12
            let inner = outer.insetBy(dx: inset, dy: inset)
            cg.setLineWidth(max(1.2, stampRadius * 0.03))
            cg.strokeEllipse(in: inner)

            // Tiny "FROM · DIANE" around the top of the stamp
            let kicker = "FROM  ·  DIANE"
            let kickerFont = UIFont(name: "Courier", size: max(9, stampRadius * 0.18))
                ?? UIFont.monospacedSystemFont(ofSize: max(9, stampRadius * 0.18), weight: .semibold)
            let kickerAttrs: [NSAttributedString.Key: Any] = [
                .font: kickerFont,
                .foregroundColor: ink.withAlphaComponent(0.9),
                .kern: 1.1
            ]
            let kickerSize = (kicker as NSString).size(withAttributes: kickerAttrs)
            (kicker as NSString).draw(
                at: CGPoint(x: -kickerSize.width / 2, y: -stampRadius * 0.42 - kickerSize.height / 2),
                withAttributes: kickerAttrs
            )

            // Handwriting name through the middle
            let baseHand =
                UIFont(name: "Snell Roundhand", size: max(22, stampRadius * 0.55))
                ?? UIFont(name: "Savoye LET", size: max(24, stampRadius * 0.58))
                ?? UIFont(name: "Apple Chancery", size: max(20, stampRadius * 0.5))
                ?? UIFont.systemFont(ofSize: max(20, stampRadius * 0.48), weight: .regular).withTraits(.traitItalic)
            let maxNameWidth = stampRadius * 1.55
            var drawName = label
            var hand = baseHand
            var nameSize = (drawName as NSString).size(withAttributes: [.font: hand])
            if nameSize.width > maxNameWidth {
                hand = baseHand.withSize(baseHand.pointSize * 0.78)
                nameSize = (drawName as NSString).size(withAttributes: [.font: hand])
                while nameSize.width > maxNameWidth, drawName.count > 8 {
                    drawName = String(drawName.dropLast())
                    nameSize = (drawName as NSString).size(withAttributes: [.font: hand])
                }
                if drawName != label { drawName += "…" }
                nameSize = (drawName as NSString).size(withAttributes: [.font: hand])
            }
            let handAttrs: [NSAttributedString.Key: Any] = [
                .font: hand,
                .foregroundColor: ink.withAlphaComponent(0.92)
            ]
            (drawName as NSString).draw(
                at: CGPoint(x: -nameSize.width / 2, y: -nameSize.height / 2 + stampRadius * 0.06),
                withAttributes: handAttrs
            )

            cg.restoreGState()
        }
        return data
    }

    private static func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "<br>")
    }
}

private extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

struct MailLetterView: UIViewControllerRepresentable {
    let tape: Tape
    var addressedTo: String = ""
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = context.coordinator
        mail.setSubject("A tape from Diane")
        mail.setMessageBody(TapeLetter.bodyHTML(for: tape), isHTML: true)
        if let data = TapeLetter.envelopePNG(addressedTo: addressedTo) {
            mail.addAttachmentData(data, mimeType: "image/png", fileName: "A tape from Diane.png")
        } else if let image = UIImage(named: "LetterFolder"), let data = image.pngData() {
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
