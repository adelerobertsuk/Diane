import AVFoundation
import Foundation

/// Cassette clicks and a typewriter. Never while the mic is live.
final class TapeSounds: NSObject, AVAudioPlayerDelegate {
    static let shared = TapeSounds()

    var enabled = true

    enum Kind {
        case play
        case stop
        case pages
        case save

        var files: [String] {
            switch self {
            case .play: ["click-play"]
            case .stop: ["click-stop"]
            case .pages: ["click-pages"]
            case .save: ["save"]
            }
        }

        var volume: Float {
            switch self {
            case .save: 0.52
            default: 0.78
            }
        }
    }

    private var live: [AVAudioPlayer] = []

    func play(_ kind: Kind) {
        guard enabled else { return }
        guard let name = kind.files.randomElement(), let url = url(for: name) else { return }
        armSession()
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.delegate = self
        player.volume = kind.volume
        player.prepareToPlay()
        live.append(player)
        player.play()
    }

    func preview() {
        play(.play)
        Task {
            try? await Task.sleep(nanoseconds: 220_000_000)
            play(.save)
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        live.removeAll { $0 === player }
    }

    private func url(for name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: name, withExtension: "wav")
    }

    private func armSession() {
        let session = AVAudioSession.sharedInstance()
        if session.category == .playAndRecord {
            try? session.setActive(true)
            return
        }
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }
}
