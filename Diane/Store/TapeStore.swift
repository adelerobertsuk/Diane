import Foundation
import SwiftUI

@Observable
final class TapeStore {
    var tapes: [Tape]
    var skin: TapeSkin
    var reminderEnabled: Bool
    var reminderHour: Int
    var reminderMinute: Int
    var weeklyLetters: [WeeklyLetter]
    var showWordsWhileTalking: Bool
    var clicksEnabled: Bool
    var displayName: String
    var aboutYou: String
    var keepVoice: Bool
    var isSaving = false

    static func load() -> TapeStore {
        TapeStore(data: Persistence.load())
    }

    init(data: AppData) {
        tapes = data.tapes.map { tape in
            var copy = tape
            copy.summary = Summarizer.forgetDianeAsSpeaker(tape.summary)
            return copy
        }
        skin = data.skin
        reminderEnabled = data.reminderEnabled
        reminderHour = data.reminderHour
        reminderMinute = data.reminderMinute
        weeklyLetters = data.weeklyLetters.map { letter in
            var copy = letter
            copy.body = Summarizer.forgetDianeAsSpeaker(letter.body)
            return copy
        }
        showWordsWhileTalking = data.showWordsWhileTalking
        clicksEnabled = data.clicksEnabled
        displayName = data.displayName
        aboutYou = data.aboutYou
        keepVoice = data.keepVoice
        TapeSounds.shared.enabled = clicksEnabled
        if tapes != data.tapes || weeklyLetters != data.weeklyLetters {
            persist()
        }
        MorningNudge.refresh(enabled: reminderEnabled, hour: reminderHour, minute: reminderMinute)
    }

    var hasMorningPagesToday: Bool {
        tapes.contains { $0.kind == .morningPages && Calendar.current.isDateInToday($0.createdAt) }
    }

    var todayTapes: [Tape] {
        tapes
            .filter { Calendar.current.isDateInToday($0.createdAt) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var recentTapes: [Tape] {
        tapes.sorted { $0.createdAt > $1.createdAt }
    }

    var thisWeekMorningPages: [Tape] {
        tapes.filter { $0.kind == .morningPages && Calendar.current.isDate($0.createdAt, equalTo: .now, toGranularity: .weekOfYear) }
            .sorted { $0.createdAt < $1.createdAt }
    }

    var thisWeekLetter: WeeklyLetter? {
        weeklyLetters.first { Calendar.current.isDate($0.weekStart, equalTo: weekStart, toGranularity: .day) }
    }

    var weekStart: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
    }

    func saveTape(transcript: String, duration: TimeInterval, voice: URL? = nil, written: Bool = false) async {
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            TapeVault.forget(voice)
            return
        }
        isSaving = true
        let kind: TapeKind = hasMorningPagesToday ? .later : .morningPages
        let summary = await Summarizer.summarize(text, kind: kind)
        var tape = Tape(kind: kind, transcript: text, summary: summary, durationSeconds: duration, written: written)
        if keepVoice, let voice {
            let compact = await TapeVault.compact(voice)
            tape.voiceFileName = TapeVault.keep(compact, as: tape.id)
        } else {
            TapeVault.forget(voice)
        }
        tapes.insert(tape, at: 0)
        persist()
        await refreshWeeklyLetterIfNeeded()
        isSaving = false
        if !written {
            TapeSounds.shared.play(.save)
        }
        Haptics.success()
    }

    func delete(_ tape: Tape) {
        TapeVault.forget(tape.voiceFileName)
        tapes.removeAll { $0.id == tape.id }
        persist()
    }

    func chooseSkin(_ newSkin: TapeSkin) {
        skin = newSkin
        persist()
    }

    func setReminder(enabled: Bool, hour: Int, minute: Int) {
        reminderEnabled = enabled
        reminderHour = hour
        reminderMinute = minute
        MorningNudge.refresh(enabled: enabled, hour: hour, minute: minute)
        persist()
    }

    func refreshWeeklyLetterIfNeeded() async {
        guard thisWeekMorningPages.count >= 3 else { return }
        if thisWeekLetter != nil { return }
        guard let body = await Summarizer.weeklyLetter(
            from: thisWeekMorningPages,
            weekStart: weekStart,
            about: aboutYou
        ) else { return }
        weeklyLetters.removeAll { Calendar.current.isDate($0.weekStart, equalTo: weekStart, toGranularity: .day) }
        weeklyLetters.insert(WeeklyLetter(weekStart: weekStart, body: body), at: 0)
        persist()
    }

    func setShowWords(_ on: Bool) {
        showWordsWhileTalking = on
        persist()
    }

    func setClicks(_ on: Bool) {
        clicksEnabled = on
        TapeSounds.shared.enabled = on
        persist()
        if on {
            TapeSounds.shared.preview()
        }
    }

    func setDisplayName(_ value: String) {
        displayName = value
        persist()
    }

    func setAboutYou(_ value: String) {
        aboutYou = value
        persist()
    }

    func setKeepVoice(_ on: Bool) {
        keepVoice = on
        persist()
    }

    var letterName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func presentedLetter(_ letter: WeeklyLetter) -> String {
        WeeklyLetterCopy.present(letter.body, name: letterName)
    }

    private func persist() {
        Persistence.save(
            AppData(
                tapes: tapes,
                skin: skin,
                reminderEnabled: reminderEnabled,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                weeklyLetters: weeklyLetters,
                showWordsWhileTalking: showWordsWhileTalking,
                clicksEnabled: clicksEnabled,
                displayName: displayName,
                aboutYou: aboutYou,
                keepVoice: keepVoice,
                skinVersion: 2
            )
        )
    }
}
