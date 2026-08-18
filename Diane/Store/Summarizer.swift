import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

enum Summarizer {
    static func summarize(_ text: String, kind: TapeKind) async -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if trimmed.split(whereSeparator: { $0.isWhitespace }).count < 40 {
            return trimmed
        }
        if let smart = await appleSummary(trimmed, kind: kind) {
            return forgetDianeAsSpeaker(smart)
        }
        return forgetDianeAsSpeaker(fallbackSummary(trimmed))
    }

    static func weeklyLetter(from tapes: [Tape], weekStart: Date) async -> String? {
        let pages = tapes.filter { $0.kind == .morningPages }
        guard pages.count >= 3 else { return nil }
        let joined = pages
            .sorted { $0.createdAt < $1.createdAt }
            .map { "\($0.createdAt.formatted(date: .abbreviated, time: .omitted))\n\($0.transcript)" }
            .joined(separator: "\n\n")
        let prompt = """
        These are one person's spoken morning pages for a week. The writer is not named Diane. Diane is the tape recorder, never the person speaking. Do not use any personal name. Write a short letter, 4 to 6 sentences, naming patterns in how they think. Stay specific to their words. No advice. No cheerleading. No questions. Do not use the em dash character. UK English.

        \(joined)
        """
        if let smart = await complete(prompt) {
            return forgetDianeAsSpeaker(smart)
        }
        return nil
    }

    private static func appleSummary(_ text: String, kind: TapeKind) async -> String? {
        let about = kind == .morningPages ? "morning pages, spoken half-awake" : "a thought spoken later in the day"
        let prompt = """
        Someone just spoke \(about) into a tape. The speaker is not named Diane. Diane is the tape recorder, never the person talking. Do not use any personal name. Never write Diane said, Diane expressed, Diane wanted, or Diane spoke. Write 2 or 3 sentences that catch what they actually said, with no name attached. No advice. No cheerleading. No questions. Do not use the em dash character. UK English.

        \(text)
        """
        return await complete(prompt)
    }

    private static func complete(_ prompt: String) async -> String? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            do {
                let session = LanguageModelSession()
                let response = try await session.respond(to: prompt)
                let body = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                return body.isEmpty ? nil : body
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }

    /// The app is called Diane. The person speaking is not.
    static func forgetDianeAsSpeaker(_ text: String) -> String {
        var result = text
        let swaps: [(String, String)] = [
            ("Diane expressed a desire to", "Wanted to"),
            ("Diane expressed a wish to", "Wanted to"),
            ("Diane expressed", "Noted"),
            ("Diane said", "Said"),
            ("Diane wanted", "Wanted"),
            ("Diane spoke", "Spoke"),
            ("Diane talked", "Talked"),
            ("Diane mentioned", "Mentioned"),
            ("Diane noted", "Noted"),
            ("Diane described", "Described"),
            ("Diane reflected", "Reflected"),
            ("Diane feels", "Felt"),
            ("Diane felt", "Felt"),
            ("Diane thinks", "Thought"),
            ("Diane thought", "Thought"),
            ("Diane has", "Had"),
            ("Diane had", "Had"),
            ("Diane was", "Was"),
            ("Diane is", "Is")
        ]
        for (from, to) in swaps {
            result = result.replacingOccurrences(of: from, with: to, options: .caseInsensitive)
        }
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = result.first else { return result }
        return first.uppercased() + result.dropFirst()
    }

    private static func fallbackSummary(_ text: String) -> String {
        let chunks = text.split { ".!?".contains($0) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 24 }
        if chunks.isEmpty {
            return String(text.prefix(220))
        }
        return chunks.prefix(3).joined(separator: ". ") + "."
    }
}
