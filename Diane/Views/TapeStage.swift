import AVFoundation
import MediaPlayer
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TapeStage: View {
    @Environment(\.palette) private var palette
    let skin: TapeSkin
    var listening: Bool
    var paused: Bool = false
    var onPause: (() -> Void)? = nil
    var onRecord: (() -> Void)? = nil
    var showsVolume: Bool = false

    private var recording: Bool { listening && !paused }

    var body: some View {
        GeometryReader { geo in
            let fill = SkinFill.map(skin: skin, view: geo.size, pressed: false)
            ZStack {
                skin.studio

                TapeFace(skin: skin, recording: recording)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                // REC lamp lives in Kate's art / video now. No software blob on top.

                if let pauseSpot = skin.pauseControl, onPause != nil {
                    hitClear(fill.frame(pauseSpot), minSide: 52) {
                        onPause?()
                    }
                    .accessibilityLabel(paused ? "Go" : "Pause")
                    .accessibilityAddTraits(.isButton)
                }

                if let recordSpot = skin.recordControl, onRecord != nil {
                    hitClear(fill.frame(recordSpot), minSide: 52) {
                        onRecord?()
                    }
                    .accessibilityLabel(listening ? "Stop recording" : "Record")
                    .accessibilityAddTraits(.isButton)
                }

                if let volumeSpot = skin.volumeControl, showsVolume {
                    VolumeHit(frame: fill.frame(volumeSpot))
                }
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func hitClear(_ frame: CGRect, minSide: CGFloat, action: @escaping () -> Void) -> some View {
        Color.clear
            .frame(width: max(minSide, frame.width), height: max(minSide, frame.height))
            .contentShape(Rectangle())
            .position(x: frame.midX, y: frame.midY)
            .highPriorityGesture(TapGesture().onEnded { action() })
    }

}

/// Invisible vertical fader over the painted Volume track. Drives system volume.
private struct VolumeHit: View {
    let frame: CGRect
    @State private var level = AVAudioSession.sharedInstance().outputVolume

    var body: some View {
        Color.clear
            .frame(width: max(44, frame.width), height: max(120, frame.height))
            .contentShape(Rectangle())
            .position(x: frame.midX, y: frame.midY)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let h = max(120, frame.height)
                        let y = drag.location.y
                        let next = Float(1 - min(1, max(0, y / h)))
                        level = next
                        SystemVolume.set(next)
                    }
            )
            .background(HiddenSystemVolume().frame(width: 1, height: 1).opacity(0.01))
            .accessibilityLabel("Volume")
            .accessibilityValue("\(Int(level * 100)) percent")
            .accessibilityAdjustableAction { direction in
                let step: Float = 0.08
                switch direction {
                case .increment: level = min(1, level + step)
                case .decrement: level = max(0, level - step)
                @unknown default: break
                }
                SystemVolume.set(level)
            }
    }
}

private enum SystemVolume {
    static weak var slider: UISlider?

    static func set(_ value: Float) {
        let clamped = min(1, max(0, value))
        if let slider {
            slider.value = clamped
            return
        }
        let box = MPVolumeView(frame: .zero)
        if let slider = box.subviews.compactMap({ $0 as? UISlider }).first {
            slider.value = clamped
        }
    }
}

private struct HiddenSystemVolume: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.alpha = 0.01
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            if let slider = view.subviews.compactMap({ $0 as? UISlider }).first {
                SystemVolume.slider = slider
            }
        }
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {
        if SystemVolume.slider == nil,
           let slider = uiView.subviews.compactMap({ $0 as? UISlider }).first {
            SystemVolume.slider = slider
        }
    }
}

/// Skin still, plus optional full-frame Kate reel loop (Diane).
struct TapeFace: UIViewRepresentable {
    var skin: TapeSkin
    var recording: Bool

    func makeUIView(context: Context) -> TapeFaceView {
        TapeFaceView()
    }

    func updateUIView(_ uiView: TapeFaceView, context: Context) {
        uiView.skin = skin
        uiView.recording = recording
        uiView.setNeedsLayout()
    }
}

final class TapeFaceView: UIView {
    var skin: TapeSkin = .diane {
        didSet {
            guard oldValue != skin else { return }
            applySkin()
        }
    }

    var recording = false {
        didSet {
            guard oldValue != recording else { return }
            applyRolling()
        }
    }

    private let wellView = UIView()
    private let skinView = UIImageView()
    private let playerLayer = AVPlayerLayer(player: CassetteDeck.shared.player)

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        clipsToBounds = true
        backgroundColor = .clear

        wellView.backgroundColor = UIColor(red: 0.11, green: 0.09, blue: 0.08, alpha: 1)
        wellView.isUserInteractionEnabled = false
        addSubview(wellView)

        skinView.contentMode = .scaleToFill
        skinView.clipsToBounds = true
        addSubview(skinView)

        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.isHidden = true
        layer.addSublayer(playerLayer)

        applySkin()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let fill = SkinFill.map(skin: skin, view: bounds.size, pressed: false)
        let plate = CGRect(origin: fill.origin, size: fill.drawn)
        skinView.frame = plate
        playerLayer.frame = plate
        wellView.frame = fill.frame(skin.cassetteWindow)
        wellView.layer.zPosition = 0
        skinView.layer.zPosition = 1
        playerLayer.zPosition = 2
    }

    private func applySkin() {
        skinView.image = UIImage(named: skin.faceImageName(recording: false))
        if let loop = skin.reelLoopName {
            CassetteDeck.shared.prepare(resource: loop)
            // Always show Kate's loop as the face so Record never flashes a different plate.
            playerLayer.isHidden = false
            skinView.isHidden = CassetteDeck.shared.player.currentItem != nil
        } else {
            playerLayer.isHidden = true
            skinView.isHidden = false
            CassetteDeck.shared.setRolling(false)
        }
        applyRolling()
        setNeedsLayout()
    }

    private func applyRolling() {
        guard skin.reelLoopName != nil else {
            CassetteDeck.shared.setRolling(false)
            return
        }
        playerLayer.isHidden = false
        skinView.isHidden = CassetteDeck.shared.player.currentItem != nil
        CassetteDeck.shared.setRolling(recording)
    }
}

struct SkinFill {
    let extraScale: CGFloat
    let drawn: CGSize
    let origin: CGPoint

    /// Wallpaper fit. Aspect-fit so Kate's margins stay; wash fills any letterbox.
    static func map(
        skin: TapeSkin,
        view: CGSize,
        pressed: Bool,
        topInset: CGFloat = 0,
        bottomInset: CGFloat = 0
    ) -> SkinFill {
        #if canImport(UIKit)
        let image = UIImage(named: skin.imageName)?.size ?? CGSize(width: 1206, height: 2622)
        #else
        let image = CGSize(width: 1206, height: 2622)
        #endif
        let usable = CGSize(
            width: max(1, view.width),
            height: max(1, view.height - topInset - bottomInset)
        )
        let extra = skin.fillScale * (pressed ? 1.01 : 1)
        let scale = min(usable.width / image.width, usable.height / image.height) * extra
        let drawn = CGSize(width: image.width * scale, height: image.height * scale)
        let origin = CGPoint(
            x: (view.width - drawn.width) / 2,
            y: topInset + (usable.height - drawn.height) / 2 + skin.fillOffsetY
        )
        return SkinFill(extraScale: extra, drawn: drawn, origin: origin)
    }

    func frame(_ spot: SkinSpot) -> CGRect {
        CGRect(
            x: origin.x + spot.x * drawn.width,
            y: origin.y + spot.y * drawn.height,
            width: spot.w * drawn.width,
            height: spot.h * drawn.height
        )
    }
}

struct VoiceWave: View {
    @Environment(\.palette) private var palette
    var level: Float
    var resting: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<28, id: \.self) { i in
                    let wave = resting ? 0.12 : sin(t * 7.2 + Double(i) * 0.42)
                    let speak = resting ? 0.12 : 0.2 + Double(max(0.08, level)) * 0.8
                    let height = 5 + speak * (8 + 26 * abs(wave))
                    Capsule()
                        .fill(resting ? palette.pause : palette.accent)
                        .frame(width: 4, height: height)
                }
            }
            .frame(height: 44)
        }
        .accessibilityHidden(true)
    }
}
