import AVFoundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Kate's cassette close-up. Muted, looping, rolls while you talk.
final class CassetteDeck {
    static let shared = CassetteDeck()

    let player: AVQueuePlayer
    private var looper: AVPlayerLooper?

    private init() {
        let queue = AVQueuePlayer()
        queue.isMuted = true
        queue.automaticallyWaitsToMinimizeStalling = true
        player = queue

        let url = Bundle.main.url(forResource: "CassetteLoop", withExtension: "mp4")
            ?? Bundle.main.url(forResource: "CassetteLoop", withExtension: "mp4", subdirectory: "Video")
        guard let url else { return }
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: queue, templateItem: item)
        queue.seek(to: CMTime(seconds: 0.4, preferredTimescale: 600))
        queue.pause()
    }

    func setRolling(_ on: Bool) {
        if on {
            player.play()
        } else {
            player.pause()
        }
    }
}

struct CassetteWell: UIViewRepresentable {
    var rolling: Bool

    func makeUIView(context: Context) -> CassetteLayerView {
        CassetteLayerView()
    }

    func updateUIView(_ uiView: CassetteLayerView, context: Context) {
        CassetteDeck.shared.setRolling(rolling)
    }
}

final class CassetteLayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        playerLayer.player = CassetteDeck.shared.player
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = UIColor.clear.cgColor
        backgroundColor = .clear
        clipsToBounds = true
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
