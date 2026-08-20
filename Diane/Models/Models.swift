import Foundation
import SwiftUI

enum TapeKind: String, Codable, Equatable {
    case morningPages
    case later

    var kicker: String {
        switch self {
        case .morningPages: "Morning pages"
        case .later: "A later tape"
        }
    }
}

enum TapeSkin: String, Codable, CaseIterable, Identifiable {
    case diane
    case cooper
    case palmer
    case earle

    var id: String { rawValue }

    /// Old saves used Cooper for gold, Noir for black, Steel for the metal one.
    static func migrated(raw: String, version: Int) -> TapeSkin {
        if version >= 2 {
            return TapeSkin(rawValue: raw) ?? .diane
        }
        switch raw {
        case "noir": return .cooper
        case "steel": return .palmer
        default: return .diane
        }
    }

    var title: String {
        switch self {
        case .diane: "Diane"
        case .cooper: "Cooper"
        case .palmer: "Palmer"
        case .earle: "Earle"
        }
    }

    var blurb: String {
        switch self {
        case .diane: "The gold one."
        case .cooper: "Quiet black, silver hardware."
        case .palmer: "A worn metal dictaphone."
        case .earle: "Brushed silver."
        }
    }

    var imageName: String {
        switch self {
        case .diane: "SkinCooper"
        case .cooper: "SkinNoir"
        case .palmer: "SkinSteel"
        case .earle: "SkinEarle"
        }
    }

    /// Kate's rec-on still, when she painted the lamp into the art.
    var recordingImageName: String? {
        switch self {
        case .diane: "SkinCooperRec"
        case .cooper: "SkinNoirRec"
        case .palmer: "SkinSteelRec"
        case .earle: "SkinEarleRec"
        }
    }

    func faceImageName(recording: Bool) -> String {
        if recording, let lit = recordingImageName { return lit }
        return imageName
    }

    var pickerImageName: String {
        switch self {
        case .diane: "SkinCooperPick"
        case .cooper: "SkinNoirPick"
        case .palmer: "SkinSteelPick"
        case .earle: "SkinEarlePick"
        }
    }

    var studio: Color {
        Color(hex: "F3EDE4")
    }

    var fillScale: CGFloat { 1 }

    var fillOffsetY: CGFloat { 0 }

    /// Soft pulse overlay. Off for now; Kate paints the lamp into stills and loops.
    var recLamp: SkinSpot? { nil }

    /// Speaker grille. Words peek sits here so branding stays clear.
    var speakerGrille: SkinSpot {
        switch self {
        case .diane: SkinSpot(x: 0.16, y: 0.46, w: 0.68, h: 0.22)
        case .cooper: SkinSpot(x: 0.14, y: 0.64, w: 0.72, h: 0.26)
        case .palmer: SkinSpot(x: 0.14, y: 0.08, w: 0.72, h: 0.22)
        case .earle: SkinSpot(x: 0.16, y: 0.52, w: 0.52, h: 0.22)
        }
    }

    /// From Kate phone-fit wallpaper (baked cassette, no video).
    var cassetteWindow: SkinSpot {
        switch self {
        case .diane: SkinSpot(x: 0.108624, y: 0.090008, w: 0.410448, h: 0.389397)
        case .cooper: SkinSpot(x: 0.22, y: 0.12, w: 0.38, h: 0.40)
        case .palmer: SkinSpot(x: 0.18, y: 0.32, w: 0.58, h: 0.24)
        case .earle: SkinSpot(x: 0.122720, y: 0.139969, w: 0.352405, h: 0.409611)
        }
    }

    /// Hardware Record key.
    var recordControl: SkinSpot? {
        switch self {
        case .diane: SkinSpot(x: 0.64, y: 0.78, w: 0.20, h: 0.12)
        case .cooper: SkinSpot(x: 0.68, y: 0.56, w: 0.16, h: 0.10)
        case .palmer: SkinSpot(x: 0.72, y: 0.74, w: 0.14, h: 0.10)
        case .earle: SkinSpot(x: 0.58, y: 0.70, w: 0.26, h: 0.14)
        }
    }

    /// Hardware Volume fader.
    var volumeControl: SkinSpot? {
        switch self {
        case .diane: SkinSpot(x: 0.56, y: 0.09, w: 0.28, h: 0.34)
        case .cooper: SkinSpot(x: 0.58, y: 0.16, w: 0.22, h: 0.32)
        case .palmer: SkinSpot(x: 0.82, y: 0.40, w: 0.14, h: 0.24)
        case .earle: SkinSpot(x: 0.45, y: 0.14, w: 0.24, h: 0.38)
        }
    }

    /// Full-frame Kate reel loop (same wallpaper composition). Nil = still only.
    var reelLoopName: String? {
        switch self {
        case .diane: "DianeKateLoop"
        case .cooper: "CooperKateLoop"
        case .palmer: "PalmerKateLoop"
        case .earle: "EarleKateLoop"
        }
    }

    var pauseControl: SkinSpot? {
        nil
    }
}

struct SkinSpot: Equatable {
    var x: CGFloat
    var y: CGFloat
    var w: CGFloat
    var h: CGFloat
}

struct Tape: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var createdAt: Date
    var kind: TapeKind
    var transcript: String
    var summary: String
    var durationSeconds: TimeInterval
    var voiceFileName: String?
    var written: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        kind: TapeKind,
        transcript: String,
        summary: String,
        durationSeconds: TimeInterval,
        voiceFileName: String? = nil,
        written: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kind = kind
        self.transcript = transcript
        self.summary = summary
        self.durationSeconds = durationSeconds
        self.voiceFileName = voiceFileName
        self.written = written
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        kind = try container.decode(TapeKind.self, forKey: .kind)
        transcript = try container.decode(String.self, forKey: .transcript)
        summary = try container.decode(String.self, forKey: .summary)
        durationSeconds = try container.decode(TimeInterval.self, forKey: .durationSeconds)
        voiceFileName = try container.decodeIfPresent(String.self, forKey: .voiceFileName)
        written = try container.decodeIfPresent(Bool.self, forKey: .written) ?? false
    }

    var displayKicker: String {
        if written, kind == .later { return "A later page" }
        return kind.kicker
    }

    var voiceURL: URL? {
        guard let voiceFileName else { return nil }
        let url = TapeVault.url(named: voiceFileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    var shareText: String {
        let when = createdAt.formatted(.dateTime.weekday(.wide).day().month(.wide).year().hour().minute())
        var lines = [
            "DIANE",
            when.uppercased(),
            "",
            kind.kicker.uppercased(),
            ""
        ]
        let summaryText = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        let pages = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !summaryText.isEmpty, summaryText != pages {
            lines += ["SUMMARY", summaryText, ""]
        }
        lines += [
            "THE PAGES",
            pages,
            "",
            "Recorded on Diane.",
            "Available on the App Store."
        ]
        return lines.joined(separator: "\n")
    }
}

struct WeeklyLetter: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var weekStart: Date
    var body: String
    var readAt: Date?

    var isUnread: Bool { readAt == nil }

    init(id: UUID = UUID(), weekStart: Date, body: String, readAt: Date? = nil) {
        self.id = id
        self.weekStart = weekStart
        self.body = body
        self.readAt = readAt
    }
}

struct AppData: Codable {
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
    var skinVersion: Int

    init(
        tapes: [Tape] = [],
        skin: TapeSkin = .diane,
        reminderEnabled: Bool = true,
        reminderHour: Int = 7,
        reminderMinute: Int = 30,
        weeklyLetters: [WeeklyLetter] = [],
        showWordsWhileTalking: Bool = false,
        clicksEnabled: Bool = true,
        displayName: String = "",
        aboutYou: String = "",
        keepVoice: Bool = true,
        skinVersion: Int = 2
    ) {
        self.tapes = tapes
        self.skin = skin
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.weeklyLetters = weeklyLetters
        self.showWordsWhileTalking = showWordsWhileTalking
        self.clicksEnabled = clicksEnabled
        self.displayName = displayName
        self.aboutYou = aboutYou
        self.keepVoice = keepVoice
        self.skinVersion = skinVersion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tapes = try container.decodeIfPresent([Tape].self, forKey: .tapes) ?? []
        let version = try container.decodeIfPresent(Int.self, forKey: .skinVersion) ?? 1
        let rawSkin = try container.decodeIfPresent(String.self, forKey: .skin) ?? "diane"
        skin = TapeSkin.migrated(raw: rawSkin, version: version)
        skinVersion = 2
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? true
        reminderHour = try container.decodeIfPresent(Int.self, forKey: .reminderHour) ?? 7
        reminderMinute = try container.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? 30
        weeklyLetters = try container.decodeIfPresent([WeeklyLetter].self, forKey: .weeklyLetters) ?? []
        showWordsWhileTalking = try container.decodeIfPresent(Bool.self, forKey: .showWordsWhileTalking) ?? false
        clicksEnabled = try container.decodeIfPresent(Bool.self, forKey: .clicksEnabled) ?? true
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        aboutYou = try container.decodeIfPresent(String.self, forKey: .aboutYou) ?? ""
        keepVoice = try container.decodeIfPresent(Bool.self, forKey: .keepVoice) ?? true
    }
}
