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
        }
    }

    var blurb: String {
        switch self {
        case .diane: "The gold one."
        case .cooper: "Quiet black, silver hardware."
        case .palmer: "A worn metal dictaphone."
        }
    }

    var imageName: String {
        switch self {
        case .diane: "SkinCooper"
        case .cooper: "SkinNoir"
        case .palmer: "SkinSteel"
        }
    }

    var pickerImageName: String {
        switch self {
        case .diane: "SkinCooperPick"
        case .cooper: "SkinNoirPick"
        case .palmer: "SkinSteelPick"
        }
    }

    var studio: Color {
        Color(hex: "F3EDE4")
    }

    var fillScale: CGFloat { 1 }

    var fillOffsetY: CGFloat { 0 }

    /// Rec glow sits on the tape, top centre of the window.
    var recLamp: SkinSpot {
        let well = cassetteWindow
        return SkinSpot(
            x: well.x + well.w * 0.47,
            y: well.y + well.h * 0.07,
            w: self == .palmer ? 0.018 : 0.026,
            h: self == .palmer ? 0.012 : 0.016
        )
    }

    var cassetteWindow: SkinSpot {
        switch self {
        case .diane: SkinSpot(x: 0.266, y: 0.368, w: 0.462, h: 0.135)
        case .cooper: SkinSpot(x: 0.194, y: 0.235, w: 0.645, h: 0.215)
        case .palmer: SkinSpot(x: 0.220, y: 0.386, w: 0.590, h: 0.150)
        }
    }

    var pauseControl: SkinSpot? {
        switch self {
        case .diane: SkinSpot(x: 0.798, y: 0.708, w: 0.050, h: 0.034)
        case .cooper: SkinSpot(x: 0.750, y: 0.548, w: 0.048, h: 0.030)
        case .palmer: nil
        }
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

struct WeeklyLetter: Identifiable, Codable, Equatable {
    var id: UUID
    var weekStart: Date
    var body: String

    init(id: UUID = UUID(), weekStart: Date, body: String) {
        self.id = id
        self.weekStart = weekStart
        self.body = body
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
