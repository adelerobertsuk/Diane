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
        case type
        case ding

        var files: [String] {
            switch self {
            case .play: ["click-play"]
            case .stop: ["click-stop"]
            case .pages: ["click-pages"]
            case .type: ["type-1", "type-2", "type-3", "type-4"]
            case .ding: ["ding"]
            }
        }

        var volume: Float {
            switch self {
            case .type: 0.55
            case .ding: 0.48
            default: 0.78
            }
        }
    }

    private var live: [AVAudioPlayer] = []
    private var typing: Task<Void, Never>?

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

    func startTyping() {
        guard enabled else { return }
        typing?.cancel()
        typing = Task { [weak self] in
            while !Task.isCancelled {
                self?.play(.type)
                let wait = UInt64.random(in: 42_000_000...88_000_000)
                try? await Task.sleep(nanoseconds: wait)
            }
        }
    }

    func stopTyping(ding: Bool = true) {
        typing?.cancel()
        typing = nil
        if ding {
            play(.ding)
        }
    }

    func preview() {
        play(.play)
        Task {
            try? await Task.sleep(nanoseconds: 160_000_000)
            startTyping()
            try? await Task.sleep(nanoseconds: 720_000_000)
            stopTyping(ding: true)
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
