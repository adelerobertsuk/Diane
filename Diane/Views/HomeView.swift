import SwiftUI

struct HomeView: View {
    @Environment(TapeStore.self) private var store
    @Environment(\.palette) private var palette
    @Environment(\.scenePhase) private var scenePhase

    @State private var listener = SpeechListener()
    @State private var finishing = false
    @State private var arming = false
    @State private var showSettings = false
    @State private var showPages = false
    @State private var showWrite = false
    @State private var tick = Date()

    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    private var elapsed: TimeInterval {
        _ = tick
        return listener.elapsed
    }

    var body: some View {
        ZStack {
            palette.bg
                .ignoresSafeArea()

            TapeStage(
                skin: store.skin,
                listening: listener.isListening,
                paused: listener.isPaused,
                onPause: listener.isListening ? { togglePause() } : nil
            )
            .ignoresSafeArea()
            .zIndex(0)
            .onTapGesture {
                if listener.isPaused {
                    togglePause()
                    return
                }
                guard !listener.isListening, !store.isSaving, !arming, !finishing else { return }
                begin()
            }

            VStack(spacing: 0) {
                chrome
                Spacer(minLength: 0)
                    .allowsHitTesting(false)
                working
            }
            .zIndex(1)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showPages) {
            PagesView()
        }
        .sheet(isPresented: $showWrite) {
            WritePagesView()
        }
        .onReceive(timer) { date in
            tick = date
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                if listener.isListening {
                    KeepAwake.start()
                }
                MorningNudge.refresh(
                    enabled: store.reminderEnabled,
                    hour: store.reminderHour,
                    minute: store.reminderMinute
                )
            }
        }
        .onDisappear {
            if listener.isListening {
                listener.stop()
            }
            KeepAwake.stop()
        }
        .task {
            await store.refreshWeeklyLetterIfNeeded()
            MorningNudge.refresh(
                enabled: store.reminderEnabled,
                hour: store.reminderHour,
                minute: store.reminderMinute
            )
        }
    }

    private var chrome: some View {
        HStack {
            Button {
                Haptics.light()
                showPages = true
            } label: {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(palette.ink)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pages")
            .opacity(listener.isListening ? 0.35 : 1)
            .disabled(listener.isListening)

            Button {
                Haptics.light()
                showWrite = true
            } label: {
                Image(systemName: "note")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(palette.faint)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Write")
            .opacity(listener.isListening ? 0.35 : 1)
            .disabled(listener.isListening)

            Spacer()

            Button {
                Haptics.light()
                showSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(palette.ink)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
            .opacity(listener.isListening ? 0.35 : 1)
            .disabled(listener.isListening)
        }
        .padding(.horizontal, 10)
        .padding(.top, 4)
        .zIndex(2)
    }

    private var recordingMeter: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(listener.isPaused ? palette.pause : palette.rec)
                    .frame(width: 8, height: 8)
                Text(listener.isPaused ? "PAUSE" : "REC")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(palette.ink)
                Text(counter)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(palette.muted)
                Spacer(minLength: 8)
                Button {
                    togglePause()
                } label: {
                    Image(systemName: listener.isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(listener.isPaused ? palette.pause : palette.ink)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(listener.isPaused ? "Go" : "Pause")
            }
            VoiceWave(level: listener.audioLevel, resting: listener.isPaused)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 28)
    }

    private var counter: String {
        let seconds = Int(elapsed)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private var wordsPeek: some View {
        Text(listener.fullText)
            .font(.system(size: 15, weight: .regular, design: .serif))
            .foregroundStyle(palette.ink.opacity(0.85))
            .lineLimit(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 22)
    }

    @ViewBuilder
    private var working: some View {
        VStack(spacing: 12) {
            if store.showWordsWhileTalking, listener.isListening, !listener.fullText.isEmpty {
                wordsPeek
            }
            bottom
            if listener.isListening {
                recordingMeter
            }
        }
        .padding(.bottom, 10)
        .safeAreaPadding(.bottom)
    }

    @ViewBuilder
    private var bottom: some View {
        VStack(spacing: 10) {
            if let error = listener.errorMessage {
                Text(error)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(palette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            if listener.isListening || store.isSaving {
                Button {
                    Task { await finish() }
                } label: {
                    Text(store.isSaving ? "Writing it down" : "That's it")
                }
                .buttonStyle(PillButtonStyle())
                .disabled(store.isSaving)
                .padding(.horizontal, Layout.screenInset)

                Button("Not this time") {
                    listener.onStopped = nil
                    listener.stop()
                    listener.discardRecording()
                    TapeSounds.shared.play(.stop)
                    finishing = false
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(palette.muted)
                .disabled(store.isSaving)
            } else {
                Text("Tap the tape.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(palette.muted)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func begin() {
        finishing = false
        arming = true
        listener.onStopped = {
            Task { await finish() }
        }
        listener.keepVoice = store.keepVoice
        Haptics.medium()
        if store.clicksEnabled {
            TapeSounds.shared.play(.play)
            Task {
                try? await Task.sleep(nanoseconds: 90_000_000)
                listener.start()
                arming = false
            }
        } else {
            listener.start()
            arming = false
        }
    }

    private func togglePause() {
        guard listener.isListening, !store.isSaving, !arming, !finishing else { return }
        if listener.isPaused {
            TapeSounds.shared.play(.play)
            listener.resumeTape()
        } else {
            TapeSounds.shared.play(.pages)
            listener.pauseTape()
        }
    }

    private func finish() async {
        guard !finishing else { return }
        finishing = true
        listener.onStopped = nil
        if listener.isListening {
            listener.stop()
            TapeSounds.shared.play(.stop)
        }
        let text = listener.fullText
        let duration = listener.elapsed
        let voice = listener.takeRecording()
        if text.isEmpty {
            TapeVault.forget(voice)
            finishing = false
            return
        }
        await store.saveTape(transcript: text, duration: duration, voice: voice)
        finishing = false
    }
}
