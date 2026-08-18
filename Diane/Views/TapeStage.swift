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

    private var recording: Bool { listening && !paused }

    var body: some View {
        GeometryReader { geo in
            let fill = SkinFill.map(skin: skin, view: geo.size, pressed: recording)
            let well = fill.frame(skin.cassetteWindow)
            ZStack {
                skin.studio
                Image(skin.imageName)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(fill.extraScale)
                    .offset(y: skin.fillOffsetY)
                    .animation(.easeInOut(duration: 0.45), value: recording)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .accessibilityHidden(true)

                CassetteWell(rolling: recording)
                    .frame(width: well.width, height: well.height)
                    .scaleEffect(skin.cassetteZoom)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: max(4, well.height * 0.08), style: .continuous))
                    .position(x: well.midX, y: well.midY)
                    .allowsHitTesting(false)

                lamp(fill.frame(skin.recLamp), on: recording, color: palette.rec, tiny: skin == .steel)

                if let pauseSpot = skin.pauseControl, onPause != nil {
                    let pauseFrame = fill.frame(pauseSpot)
                    pauseGlow(pauseFrame, on: paused)
                    Color.clear
                        .frame(width: max(52, pauseFrame.width), height: max(52, pauseFrame.height))
                        .contentShape(Rectangle())
                        .position(x: pauseFrame.midX, y: pauseFrame.midY)
                        .highPriorityGesture(TapGesture().onEnded {
                            onPause?()
                        })
                        .accessibilityLabel(paused ? "Go" : "Pause")
                        .accessibilityAddTraits(.isButton)
                }
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private func lamp(_ frame: CGRect, on: Bool, color: Color, tiny: Bool) -> some View {
        TimelineView(.animation(minimumInterval: 1 / 24)) { timeline in
            let pulse = on
                ? 0.62 + 0.38 * sin(timeline.date.timeIntervalSinceReferenceDate * 3.1)
                : 0.0
            ZStack {
                Circle()
                    .fill(color)
                    .blur(radius: tiny ? 5 : 9)
                    .opacity(pulse)
                Circle()
                    .fill(color)
                    .opacity(pulse)
            }
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
            .allowsHitTesting(false)
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func pauseGlow(_ frame: CGRect, on: Bool) -> some View {
        RoundedRectangle(cornerRadius: max(8, frame.width * 0.18), style: .continuous)
            .fill(palette.pause.opacity(on ? 0.42 : 0))
            .overlay(
                RoundedRectangle(cornerRadius: max(8, frame.width * 0.18), style: .continuous)
                    .strokeBorder(palette.pause.opacity(on ? 0.95 : 0), lineWidth: 3)
            )
            .shadow(color: palette.pause.opacity(on ? 0.85 : 0), radius: on ? 14 : 0)
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
            .animation(.easeOut(duration: 0.22), value: on)
            .allowsHitTesting(false)
    }
}

private struct SkinFill {
    let extraScale: CGFloat
    let drawn: CGSize
    let origin: CGPoint

    static func map(skin: TapeSkin, view: CGSize, pressed: Bool) -> SkinFill {
        #if canImport(UIKit)
        let image = UIImage(named: skin.imageName)?.size ?? CGSize(width: 1170, height: 2080)
        #else
        let image = CGSize(width: 1170, height: 2080)
        #endif
        let extra = skin.fillScale * (pressed ? 1.01 : 1)
        let scale = max(view.width / image.width, view.height / image.height) * extra
        let drawn = CGSize(width: image.width * scale, height: image.height * scale)
        let origin = CGPoint(
            x: (view.width - drawn.width) / 2,
            y: (view.height - drawn.height) / 2 + skin.fillOffsetY
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

