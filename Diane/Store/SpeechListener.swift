import AVFoundation
import Foundation
import MediaPlayer
import Speech
import UIKit

/// Live dictation that writes the voice onto this phone, does not stop on silence,
/// and does not die when the phone locks.
@Observable
final class SpeechListener {
    var keepVoice = true
    var isListening = false
    var isPaused = false
    var liveTranscript = ""
    var committedTranscript = ""
    var audioLevel: Float = 0
    var permissionDenied = false
    var errorMessage: String?
    var startedAt: Date?
    var onStopped: (() -> Void)?

    var isRecording: Bool { isListening && !isPaused }

    var fullText: String {
        [committedTranscript, liveTranscript]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var elapsed: TimeInterval {
        guard let startedAt else { return 0 }
        var total = Date().timeIntervalSince(startedAt) - pauseTotal
        if let pauseBegan {
            total -= Date().timeIntervalSince(pauseBegan)
        }
        return max(0, total)
    }

    private let audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var keepAlivePlayer: AVAudioPlayer?
    private var chunkStarted = Date()
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var sleepActivity: NSObjectProtocol?
    private var interruptionObserver: NSObjectProtocol?
    private var tapInstalled = false
    private var chunkID = UUID()
    private var pauseTotal: TimeInterval = 0
    private var pauseBegan: Date?
    private var tapeFile: AVAudioFile?
    private var tapeURL: URL?
    private let tapeLock = NSLock()

    private let chunkLimit: TimeInterval = 40

    /// Closed recording, ready to keep with the pages. Nil if nothing was captured.
    func takeRecording() -> URL? {
        closeTapeFile()
        let url = tapeURL
        tapeURL = nil
        return url
    }

    func discardRecording() {
        closeTapeFile()
        TapeVault.forget(tapeURL)
        tapeURL = nil
    }

    func start() {
        guard !isListening else { return }
        errorMessage = nil
        requestPermissionsThenStart()
    }

    func pauseTape() {
        guard isListening, !isPaused else { return }
        commitLive()
        isPaused = true
        pauseBegan = Date()
        if audioEngine.isRunning {
            audioEngine.pause()
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        audioLevel = 0
        showLockScreenNowPlaying()
        Haptics.medium()
    }

    func resumeTape() {
        guard isListening, isPaused else { return }
        if let pauseBegan {
            pauseTotal += Date().timeIntervalSince(pauseBegan)
        }
        pauseBegan = nil
        isPaused = false
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            if !audioEngine.isRunning {
                try audioEngine.start()
            }
        } catch {
            errorMessage = "Could not start listening."
            return
        }
        beginRecognitionTask()
        keepAlivePlayer?.play()
        KeepAwake.start()
        showLockScreenNowPlaying()
        Haptics.medium()
    }

    func stop() {
        guard isListening || audioEngine.isRunning else {
            teardown(playHaptic: false)
            return
        }
        commitLive()
        closeTapeFile()
        teardown(playHaptic: true)
        onStopped?()
    }

    private func requestPermissionsThenStart() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            AVAudioApplication.requestRecordPermission { granted in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    guard status == .authorized, granted else {
                        self.permissionDenied = true
                        self.errorMessage = "Diane needs the microphone and speech permission. Both stay on this phone."
                        return
                    }
                    self.permissionDenied = false
                    self.beginSession()
                }
            }
        }
    }

    private func beginSession() {
        teardownAudioEngineOnly()
        discardRecording()

        speechRecognizer = SFSpeechRecognizer(locale: Locale.autoupdatingCurrent)
            ?? SFSpeechRecognizer(locale: Locale(identifier: "en-GB"))

        committedTranscript = ""
        liveTranscript = ""
        startedAt = Date()
        chunkStarted = Date()
        isPaused = false
        pauseTotal = 0
        pauseBegan = nil

        KeepAwake.start()
        sleepActivity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Diane is listening"
        )
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "DianeTape") { [weak self] in
            self?.endBackgroundTask()
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .spokenAudio,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .mixWithOthers, .duckOthers]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Could not open the microphone."
            teardown(playHaptic: false)
            return
        }

        startKeepAliveTone()
        installTapIfNeeded()
        beginRecognitionTask()
        showLockScreenNowPlaying()
        observeInterruptions()

        audioEngine.prepare()
        do {
            isListening = true
            try audioEngine.start()
        } catch {
            isListening = false
            errorMessage = "Could not start listening."
            teardown(playHaptic: false)
            return
        }

        Haptics.medium()
    }

    private func beginRecognitionTask() {
        recognitionTask?.cancel()
        recognitionRequest?.endAudio()
        recognitionTask = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        request.taskHint = .dictation
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request
        chunkStarted = Date()

        let id = UUID()
        chunkID = id
        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self, self.isListening, !self.isPaused, self.chunkID == id else { return }
                if let result {
                    self.liveTranscript = result.bestTranscription.formattedString
                }
                if error != nil {
                    self.rotateChunk()
                    return
                }
                if Date().timeIntervalSince(self.chunkStarted) >= self.chunkLimit {
                    self.rotateChunk()
                }
            }
        }
    }

    private func rotateChunk() {
        commitLive()
        beginRecognitionTask()
    }

    private func commitLive() {
        let piece = liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !piece.isEmpty {
            if committedTranscript.isEmpty {
                committedTranscript = piece
            } else {
                committedTranscript += " " + piece
            }
        }
        liveTranscript = ""
    }

    private func installTapIfNeeded() {
        guard !tapInstalled else { return }
        let input = audioEngine.inputNode
        input.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
            guard let self, self.isListening, !self.isPaused else { return }
            self.recognitionRequest?.append(buffer)
            self.appendTape(buffer)
            let level = SpeechListener.rmsLevel(buffer: buffer)
            Task { @MainActor [weak self] in
                guard let self, self.isRecording else { return }
                self.audioLevel = min(1, (self.audioLevel * 0.55) + (level * 0.45))
            }
        }
        tapInstalled = true
    }

    private func appendTape(_ buffer: AVAudioPCMBuffer) {
        guard keepVoice else { return }
        tapeLock.lock()
        defer { tapeLock.unlock() }
        if tapeFile == nil {
            openTapeFileLocked(format: buffer.format)
        }
        try? tapeFile?.write(from: buffer)
    }

    private func openTapeFileLocked(format: AVAudioFormat) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("diane-\(UUID().uuidString).caf")
        let rate = format.sampleRate > 0 ? format.sampleRate : 44_100
        let channels = max(1, format.channelCount)
        do {
            let file = try AVAudioFile(
                forWriting: url,
                settings: [
                    AVFormatIDKey: Int(kAudioFormatLinearPCM),
                    AVSampleRateKey: rate,
                    AVNumberOfChannelsKey: channels,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsBigEndianKey: false,
                    AVLinearPCMIsNonInterleaved: true
                ],
                commonFormat: format.commonFormat,
                interleaved: format.isInterleaved
            )
            tapeFile = file
            tapeURL = url
        } catch {
            tapeFile = nil
            tapeURL = nil
        }
    }

    private func closeTapeFile() {
        tapeLock.lock()
        tapeFile = nil
        tapeLock.unlock()
    }

    private func startKeepAliveTone() {
        let data = SpeechListener.silenceWAV()
        keepAlivePlayer = try? AVAudioPlayer(data: data)
        keepAlivePlayer?.numberOfLoops = -1
        keepAlivePlayer?.volume = 0.004
        keepAlivePlayer?.prepareToPlay()
        keepAlivePlayer?.play()
    }

    private func showLockScreenNowPlaying() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.pauseCommand.isEnabled = true
        center.stopCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true

        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.stopCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)

        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.resumeTape() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.pauseTape() }
            return .success
        }
        center.stopCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.stop() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if self.isPaused {
                    self.resumeTape()
                } else {
                    self.pauseTape()
                }
            }
            return .success
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: "Tape",
            MPMediaItemPropertyArtist: isPaused ? "Paused" : "Listening",
            MPNowPlayingInfoPropertyPlaybackRate: isPaused ? 0.0 : 1.0,
            MPNowPlayingInfoPropertyIsLiveStream: true
        ]
        if let image = UIImage(named: TapeSkin.diane.imageName) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    private func observeInterruptions() {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard isListening else { return }
        let info = notification.userInfo
        let typeValue = info?[AVAudioSessionInterruptionTypeKey] as? UInt
        let type = typeValue.flatMap(AVAudioSession.InterruptionType.init(rawValue:))

        if type == .ended {
            let optionsValue = info?[AVAudioSessionInterruptionOptionKey] as? UInt
            let options = optionsValue.map { AVAudioSession.InterruptionOptions(rawValue: $0) } ?? []
            if options.contains(.shouldResume) || options.isEmpty {
                try? AVAudioSession.sharedInstance().setActive(true)
                if isPaused {
                    keepAlivePlayer?.play()
                    return
                }
                if !audioEngine.isRunning {
                    try? audioEngine.start()
                }
                keepAlivePlayer?.play()
                KeepAwake.start()
            }
        }
    }

    private func teardown(playHaptic: Bool) {
        isListening = false
        isPaused = false
        pauseBegan = nil
        pauseTotal = 0
        teardownAudioEngineOnly()
        keepAlivePlayer?.stop()
        keepAlivePlayer = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPRemoteCommandCenter.shared().playCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().pauseCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().stopCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.removeTarget(nil)
        KeepAwake.stop()
        if let sleepActivity {
            ProcessInfo.processInfo.endActivity(sleepActivity)
            self.sleepActivity = nil
        }
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
            self.interruptionObserver = nil
        }
        endBackgroundTask()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        audioLevel = 0
        if playHaptic {
            Haptics.medium()
        }
    }

    private func teardownAudioEngineOnly() {
        if tapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }

    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    private static func rmsLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0 }
        let samples = channelData[0]
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += samples[i] * samples[i]
        }
        return min(1, sqrtf(sum / Float(frameLength)) * 8)
    }

    /// A one-second silent WAV so iOS treats Diane as a living audio app
    /// on the lock screen. The real voice is written to the tape file separately.
    private static func silenceWAV() -> Data {
        let sampleRate: UInt32 = 8000
        let samples: UInt32 = 8000
        let dataSize = samples * 2
        var data = Data()
        func ascii(_ value: String) { data.append(contentsOf: value.utf8) }
        func le32(_ value: UInt32) {
            var value = value.littleEndian
            withUnsafeBytes(of: &value) { data.append(contentsOf: $0) }
        }
        func le16(_ value: UInt16) {
            var value = value.littleEndian
            withUnsafeBytes(of: &value) { data.append(contentsOf: $0) }
        }
        ascii("RIFF")
        le32(36 + dataSize)
        ascii("WAVE")
        ascii("fmt ")
        le32(16)
        le16(1)
        le16(1)
        le32(sampleRate)
        le32(sampleRate * 2)
        le16(2)
        le16(16)
        ascii("data")
        le32(dataSize)
        data.append(Data(count: Int(dataSize)))
        return data
    }
}
