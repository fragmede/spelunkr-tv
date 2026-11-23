import AVFoundation
import OSLog
import SpelunkrCore

/// A separate player preserves the site's music bed without replacing video audio.
@MainActor
final class BroadcastAudioPlayer {
    private(set) var errorMessage: String?
    private let player = AVPlayer()
    private var currentID: String?
    private var needsSeek = false
    private var seekTask: Task<Void, Never>?
    private var loadedAt = Date.now
    private let logger = Logger(subsystem: "org.fragmede.SpelunkrTV", category: "Soundtrack")

    func update(_ audio: AudioPlayback?, playing: Bool) {
        guard let audio else { stop(); return }
        if currentID != audio.id {
            stop()
            currentID = audio.id
            player.replaceCurrentItem(with: AVPlayerItem(url: audio.url))
            loadedAt = .now
            needsSeek = true
        }
        guard errorMessage == nil else { return }
        player.volume = Float(audio.volume)
        guard playing else {
            seekTask?.cancel()
            seekTask = nil
            player.currentItem?.cancelPendingSeeks()
            player.pause()
            needsSeek = true
            return
        }
        guard let item = player.currentItem else { return }
        if item.status == .failed {
            fail()
            return
        }
        guard item.status == .readyToPlay else {
            if Date.now.timeIntervalSince(loadedAt) > 30 { fail() }
            return
        }
        if let seekTask, Date.now.timeIntervalSince(loadedAt) > 30 {
            seekTask.cancel()
            item.cancelPendingSeeks()
            self.seekTask = nil
            fail()
            return
        }
        guard needsSeek, seekTask == nil else { return }
        needsSeek = false
        loadedAt = .now
        seekTask = Task { [weak self] in
            guard let self else { return }
            let completed = await player.seek(to: CMTime(seconds: audio.offset, preferredTimescale: 600))
            guard !Task.isCancelled, currentID == audio.id else { return }
            seekTask = nil
            if completed {
                player.play()
                logger.info("Soundtrack ready: \(audio.title, privacy: .public) at \(audio.offset) seconds")
            } else {
                fail()
            }
        }
    }

    func stop() {
        seekTask?.cancel()
        seekTask = nil
        player.currentItem?.cancelPendingSeeks()
        player.pause()
        if currentID != nil { player.replaceCurrentItem(with: nil) }
        currentID = nil
        needsSeek = false
        errorMessage = nil
    }

    private func fail() {
        player.pause()
        needsSeek = true
        errorMessage = "This channel’s soundtrack couldn’t be loaded. Try again or choose another channel."
    }
}
