import AVFoundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Kate's cassette / machine loops. Muted. Rolls while you talk.
final class CassetteDeck {
    static let shared = CassetteDeck()

    let player: AVQueuePlayer
    private var looper: AVPlayerLooper?
    private var loadedName: String?

    private init() {
        let queue = AVQueuePlayer()
        queue.isMuted = true
        queue.automaticallyWaitsToMinimizeStalling = true
        player = queue
    }

    func prepare(resource: String) {
        guard loadedName != resource else { return }
        loadedName = resource
        looper = nil
        player.removeAllItems()

        let url = Bundle.main.url(forResource: resource, withExtension: "mp4")
            ?? Bundle.main.url(forResource: resource, withExtension: "mp4", subdirectory: "Video")
            ?? Bundle.main.url(forResource: resource, withExtension: "mov")
            ?? Bundle.main.url(forResource: resource, withExtension: "mov", subdirectory: "Video")
        guard let url else { return }
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: player, templateItem: item)
        player.seek(to: .zero)
        player.pause()
    }

    func setRolling(_ on: Bool) {
        if on {
            if player.rate == 0 {
                player.play()
            }
        } else {
            player.pause()
            // Stay on the current frame / start so idle matches Kate's still.
            player.seek(to: .zero)
        }
    }
}

// MARK: - Layered Diane cassette (stub art OK; champagne pack later)

struct CassettePlateLayout {
    /// Plate is the window aperture (720×1080). Centres normalised 0–1 of plate.
    var reelLeft = ReelSpot(centerX: 0.458333, centerY: 0.310185, diameter: 0.340278)
    var reelRight = ReelSpot(centerX: 0.458333, centerY: 0.689815, diameter: 0.340278)
    var degreesPerSecond: CGFloat = 150
    var easeInSeconds: CFTimeInterval = 0.35
    var easeOutSeconds: CFTimeInterval = 0.5

    struct ReelSpot {
        var centerX: CGFloat
        var centerY: CGFloat
        var diameter: CGFloat
    }

    static let diane = CassettePlateLayout()
}

/// Well → reels → shell → glass under the skin alpha hole.
struct LayeredCassette: UIViewRepresentable {
    var rolling: Bool
    var layout: CassettePlateLayout = .diane

    func makeUIView(context: Context) -> LayeredCassetteView {
        LayeredCassetteView(layout: layout)
    }

    func updateUIView(_ uiView: LayeredCassetteView, context: Context) {
        uiView.layout = layout
        uiView.setRolling(rolling)
    }
}

final class LayeredCassetteView: UIView {
    var layout: CassettePlateLayout {
        didSet { setNeedsLayout() }
    }

    private let well = UIImageView()
    private let reelLeft = UIImageView()
    private let reelRight = UIImageView()
    private let shell = UIImageView()
    private let glass = UIImageView()

    private var displayLink: CADisplayLink?
    private var rolling = false
    private var speed: CGFloat = 0
    private var angleLeft: CGFloat = 0
    private var angleRight: CGFloat = 0
    private var lastTick: CFTimeInterval = 0

    init(layout: CassettePlateLayout) {
        self.layout = layout
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        clipsToBounds = true
        backgroundColor = .clear

        for view in [well, reelLeft, reelRight, shell, glass] {
            view.contentMode = .scaleToFill
            view.clipsToBounds = false
            addSubview(view)
        }

        backgroundColor = UIColor(red: 0.11, green: 0.09, blue: 0.08, alpha: 1)
        well.image = UIImage(named: "CassetteDianeWell")
        reelLeft.image = UIImage(named: "CassetteDianeReelLeft")
        reelRight.image = UIImage(named: "CassetteDianeReelRight")
        shell.image = UIImage(named: "CassetteDianeShell")
        glass.image = UIImage(named: "CassetteDianeGlass")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        displayLink?.invalidate()
    }

    func setRolling(_ on: Bool) {
        guard rolling != on else { return }
        rolling = on
        lastTick = CACurrentMediaTime()
        if on {
            startLink()
        } else if displayLink == nil {
            startLink()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let plate = bounds
        well.frame = plate
        shell.frame = plate
        glass.frame = plate
        place(reelLeft, layout.reelLeft, in: plate)
        place(reelRight, layout.reelRight, in: plate)
        applyAngles()
    }

    private func place(_ view: UIImageView, _ spot: CassettePlateLayout.ReelSpot, in plate: CGRect) {
        let d = spot.diameter * min(plate.width, plate.height)
        let cx = plate.minX + spot.centerX * plate.width
        let cy = plate.minY + spot.centerY * plate.height
        view.bounds = CGRect(x: 0, y: 0, width: d, height: d)
        view.center = CGPoint(x: cx, y: cy)
    }

    private func startLink() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        displayLink = link
        lastTick = CACurrentMediaTime()
    }

    private func stopLinkIfIdle() {
        guard !rolling, abs(speed) < 0.5 else { return }
        speed = 0
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        let dt = min(1 / 30, max(0, now - lastTick))
        lastTick = now

        let target: CGFloat = rolling ? layout.degreesPerSecond : 0
        let ease = rolling ? layout.easeInSeconds : layout.easeOutSeconds
        let step = ease > 0 ? CGFloat(dt / ease) : 1
        speed += (target - speed) * min(1, step)

        if abs(speed) > 0.01 {
            let delta = speed * CGFloat(dt)
            // Opposite spins so tape feeds between reels.
            angleLeft += delta
            angleRight -= delta
            applyAngles()
        }

        stopLinkIfIdle()
    }

    private func applyAngles() {
        reelLeft.transform = CGAffineTransform(rotationAngle: angleLeft * .pi / 180)
        reelRight.transform = CGAffineTransform(rotationAngle: angleRight * .pi / 180)
    }
}
