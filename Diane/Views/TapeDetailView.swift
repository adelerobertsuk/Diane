import AVFoundation
import SwiftUI

struct TapeDetailView: View {
    @Environment(TapeStore.self) private var store
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss
    let tape: Tape
    @State private var showLetter = false
    @State private var showTextShare = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(tape.displayKicker)
                    .kickerStyle()

                Text(tape.createdAt.formatted(.dateTime.weekday(.wide).day().month(.wide).hour().minute()))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(palette.muted)

                if let voice = tape.voiceURL {
                    TapeListenButton(url: voice)
                }

                if hasDistinctSummary {
                    Text("Summary")
                        .kickerStyle()
                        .padding(.top, 6)

                    Text(tape.summary)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(palette.muted)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Layout.cardPadding)
                        .cardBackground()
                }

                Text("The pages")
                    .kickerStyle()
                    .padding(.top, 8)

                Text("“\(tape.transcript)”")
                    .readingStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Layout.cardPadding)
                    .cardBackground()

                Button("Delete this tape") {
                    Haptics.light()
                    store.delete(tape)
                    dismiss()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(palette.muted)
                .padding(.top, 8)
            }
            .padding(.horizontal, Layout.screenInset)
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .sanctuaryBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.light()
                    if TapeLetter.canSend {
                        showLetter = true
                    } else {
                        showTextShare = true
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(palette.ink)
                }
                .accessibilityLabel("Send a letter")
            }
        }
        .sheet(isPresented: $showLetter) {
            MailLetterView(tape: tape, isPresented: $showLetter)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showTextShare) {
            ShareSheet(items: shareItems)
        }
    }

    private var shareItems: [Any] {
        if let voice = tape.voiceURL {
            return [tape.shareText, voice]
        }
        return [tape.shareText]
    }

    private var hasDistinctSummary: Bool {
        tape.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            != tape.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct TapeListenButton: View {
    @Environment(\.palette) private var palette
    let url: URL
    @State private var player: AVAudioPlayer?
    @State private var playing = false
    @State private var watch = PlayerEndWatch()

    var body: some View {
        Button {
            toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: playing ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(playing ? "Playing" : "Listen")
                        .font(.system(size: 16, weight: .medium))
                    Text("The voice stays on this phone.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(palette.muted)
                }
                Spacer()
            }
            .foregroundStyle(palette.ink)
            .padding(Layout.cardPadding)
            .cardBackground()
        }
        .buttonStyle(.plain)
        .onAppear {
            watch.onEnd = {
                playing = false
            }
        }
        .onDisappear {
            player?.stop()
            playing = false
        }
    }

    private func toggle() {
        Haptics.light()
        if playing {
            player?.pause()
            playing = false
            return
        }
        if player == nil {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try? session.setActive(true)
            player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
        }
        player?.play()
        playing = true
        player?.delegate = watch
    }
}

private final class PlayerEndWatch: NSObject, AVAudioPlayerDelegate {
    var onEnd: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onEnd?()
    }
}
