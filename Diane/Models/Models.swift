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
    case cooper
    case noir
    case steel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cooper: "Cooper"
        case .noir: "Noir"
        case .steel: "Steel"
        }
    }

    var blurb: String {
        switch self {
        case .cooper: "The gold one."
        case .noir: "Quiet black, silver hardware."
        case .steel: "A worn metal dictaphone."
        }
    }

    var imageName: String {
        switch self {
        case .cooper: "SkinCooper"
        case .noir: "SkinNoir"
        case .steel: "SkinSteel"
        }
    }

    var pickerImageName: String {
        switch self {
        case .cooper: "SkinCooperPick"
        case .noir: "SkinNoirPick"
        case .steel: "SkinSteelPick"
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
            w: self == .steel ? 0.018 : 0.026,
            h: self == .steel ? 0.012 : 0.016
        )
    }

    var cassetteWindow: SkinSpot {
        switch self {
        case .cooper: SkinSpot(x: 0.266, y: 0.368, w: 0.462, h: 0.135)
        case .noir: SkinSpot(x: 0.232, y: 0.312, w: 0.528, h: 0.168)
        case .steel: SkinSpot(x: 0.234, y: 0.392, w: 0.512, h: 0.128)
        }
    }

    /// Extra zoom so Kate's cassette fills the well, not a grey mat.
    var cassetteZoom: CGFloat {
        switch self {
        case .cooper: 1.16
        case .noir: 1.18
        case .steel: 1.22
        }
    }

    var pauseControl: SkinSpot? {
        switch self {
        case .cooper: SkinSpot(x: 0.755, y: 0.585, w: 0.100, h: 0.070)
        case .noir, .steel: nil
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

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        kind: TapeKind,
        transcript: String,
        summary: String,
        durationSeconds: TimeInterval
    ) {
        self.id = id
        self.createdAt = createdAt
        self.kind = kind
        self.transcript = transcript
        self.summary = summary
        self.durationSeconds = durationSeconds
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

    init(
        tapes: [Tape] = [],
        skin: TapeSkin = .cooper,
        reminderEnabled: Bool = true,
        reminderHour: Int = 7,
        reminderMinute: Int = 30,
        weeklyLetters: [WeeklyLetter] = [],
        showWordsWhileTalking: Bool = false,
        clicksEnabled: Bool = true
    ) {
        self.tapes = tapes
        self.skin = skin
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.weeklyLetters = weeklyLetters
        self.showWordsWhileTalking = showWordsWhileTalking
        self.clicksEnabled = clicksEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tapes = try container.decodeIfPresent([Tape].self, forKey: .tapes) ?? []
        skin = try container.decodeIfPresent(TapeSkin.self, forKey: .skin) ?? .cooper
        reminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .reminderEnabled) ?? true
        reminderHour = try container.decodeIfPresent(Int.self, forKey: .reminderHour) ?? 7
        reminderMinute = try container.decodeIfPresent(Int.self, forKey: .reminderMinute) ?? 30
        weeklyLetters = try container.decodeIfPresent([WeeklyLetter].self, forKey: .weeklyLetters) ?? []
        showWordsWhileTalking = try container.decodeIfPresent(Bool.self, forKey: .showWordsWhileTalking) ?? false
        clicksEnabled = try container.decodeIfPresent(Bool.self, forKey: .clicksEnabled) ?? true
    }
}
