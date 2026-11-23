import AVFoundation
import Observation
import OSLog
import SpelunkrCore

@MainActor
@Observable
final class PlaybackModel {
    let player = AVPlayer()
    private(set) var channel: Channel?
    private(set) var airing: Airing?
    private(set) var isLoading = true
    private(set) var errorMessage: String?
    private(set) var isActive = true

    @ObservationIgnored private let guide: GuideModel
    @ObservationIgnored private var schedule: ChannelSchedule?
    @ObservationIgnored private var tuneTask: Task<Void, Never>?
    @ObservationIgnored private var catalogTask: Task<Void, Never>?
    @ObservationIgnored private var seekTask: Task<Void, Never>?
    @ObservationIgnored private let audioPlayer = BroadcastAudioPlayer()
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var pendingSeek = false
    @ObservationIgnored private var itemLoadedAt = Date.now
    @ObservationIgnored private var stalledSince: Date?
    @ObservationIgnored private var isTuning = false
    @ObservationIgnored private var wasPaused = false
    @ObservationIgnored private let logger = Logger(subsystem: "org.fragmede.SpelunkrTV", category: "Playback")

    init(guide: GuideModel) {
        self.guide = guide
        player.automaticallyWaitsToMinimizeStalling = true
    }

    var isBroadcastCard: Bool { airing != nil && airing?.mediaURL == nil && errorMessage == nil }

    var cardText: String {
        guard let airing else { return "Tuning in…" }
        return airing.currentSlide ?? airing.title
    }

    func run(channelID: String) async {
        // Full-screen presentation may suspend the guide view's task. Keep
        // catalog refresh alive for someone watching one channel all evening.
        catalogTask = Task { [guide] in
            while !Task.isCancelled {
                if Date.now.timeIntervalSince(guide.lastUpdated ?? .distantPast) >= 900 {
                    await guide.refresh()
                }
                do { try await Task.sleep(for: .seconds(60)) } catch { return }
            }
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("Audio setup failed: \(error.localizedDescription)")
        }
        await tune(to: channelID)
        while !Task.isCancelled {
            await tick()
            do {
                try await Task.sleep(for: .milliseconds(500))
            } catch {
                break
            }
        }
        stop()
    }

    func switchChannel(_ direction: Int) {
        guard let channel, let next = guide.adjacentChannel(to: channel.id, direction: direction) else { return }
        requestTune(to: next.id)
    }

    func retry() {
        guard let channel else { return }
        requestTune(to: channel.id, reload: true)
    }

    func goLive() {
        guard let schedule else { retry(); return }
        load(schedule.airing(at: .now))
    }

    func setActive(_ active: Bool) {
        isActive = active
        if active {
            goLive()
        } else {
            player.pause()
            audioPlayer.stop()
        }
    }

    func stop() {
        generation = UUID()
        tuneTask?.cancel()
        tuneTask = nil
        catalogTask?.cancel()
        catalogTask = nil
        cancelSeek()
        audioPlayer.stop()
        player.pause()
        player.replaceCurrentItem(with: nil)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func requestTune(to id: String, reload: Bool = false) {
        tuneTask?.cancel()
        tuneTask = Task { await tune(to: id, reload: reload) }
    }

    private func tune(to id: String, reload: Bool = false) async {
        let token = UUID()
        generation = token
        channel = guide.channel(id: id)
        guide.focusedChannelID = id
        isTuning = true
        isLoading = true
        errorMessage = nil
        airing = nil
        schedule = nil
        cancelSeek()
        audioPlayer.stop()
        player.pause()
        player.replaceCurrentItem(with: nil)
        do {
            let loaded = try await guide.schedule(for: id, reload: reload)
            guard token == generation, !Task.isCancelled else { return }
            schedule = loaded
            isTuning = false
            load(loaded.airing(at: .now))
        } catch {
            guard token == generation, !Task.isCancelled else { return }
            isTuning = false
            isLoading = false
            errorMessage = "This channel’s schedule is unavailable. Try again or tune to another channel."
            logger.error("Schedule failed for \(id, privacy: .public): \(error.localizedDescription)")
        }
    }

    private func load(_ next: Airing) {
        cancelSeek()
        audioPlayer.stop()
        player.pause()
        airing = next
        errorMessage = nil
        stalledSince = nil
        pendingSeek = false
        wasPaused = false
        guard let url = next.mediaURL else {
            player.replaceCurrentItem(with: nil)
            isLoading = false
            return
        }
        let item = AVPlayerItem(url: url)
        item.externalMetadata = metadata(for: next)
        item.forwardPlaybackEndTime = CMTime(seconds: next.mediaOffset + next.remaining, preferredTimescale: 600)
        player.isMuted = channel?.audioOverlay == true && next.kind == .video
        player.volume = Float(min(1, pow(10, (next.advertisementGainDb ?? 0) / 20)))
        player.replaceCurrentItem(with: item)
        itemLoadedAt = .now
        pendingSeek = true
        isLoading = true
        logger.info("Tuning \(self.channel?.id ?? "", privacy: .public): \(next.title, privacy: .public)")
    }

    private func tick() async {
        if let channel, let refreshed = guide.cachedSchedule(for: channel.id) {
            schedule = refreshed
        }
        guard isActive, !isTuning, let schedule else { return }
        let current = schedule.airing(at: .now)
        if current.id != airing?.id {
            load(current)
        } else {
            airing = current
        }
        guard errorMessage == nil else { return }
        if let item = player.currentItem, item.status == .readyToPlay,
           !pendingSeek, seekTask == nil, errorMessage == nil {
            if wasPaused, player.rate > 0 {
                // Resuming rejoins the broadcast, keeping video and its music
                // on the same clock even after a long pause.
                wasPaused = false
                player.pause()
                audioPlayer.stop()
                pendingSeek = true
                itemLoadedAt = .now
                isLoading = true
            } else if player.timeControlStatus == .paused {
                wasPaused = true
            }
        }
        audioPlayer.update(current.audio, playing: errorMessage == nil && (isBroadcastCard || player.rate > 0))
        if let audioError = audioPlayer.errorMessage { fail(audioError) }
        guard let item = player.currentItem, errorMessage == nil else { return }
        switch item.status {
        case .failed:
            fail("This tape couldn’t be played from the Internet Archive. Try again or choose another channel.")
            logger.error("Media failed: \(item.error?.localizedDescription ?? "Unknown playback error")")
        case .unknown:
            if Date.now.timeIntervalSince(itemLoadedAt) > 45 {
                fail("This tape is taking too long to load. Try again or choose another channel.")
            }
        case .readyToPlay:
            if pendingSeek {
                pendingSeek = false
                seekTask = Task { [weak self] in
                    guard let self else { return }
                    let target = CMTime(seconds: current.mediaOffset, preferredTimescale: 600)
                    let tolerance = CMTime(seconds: 0.25, preferredTimescale: 600)
                    let completed = await player.seek(to: target, toleranceBefore: tolerance, toleranceAfter: tolerance)
                    guard item === player.currentItem, isActive, !Task.isCancelled else { return }
                    seekTask = nil
                    if completed {
                        player.play()
                        isLoading = false
                        logger.info("Playback ready at \(current.mediaOffset) seconds")
                    } else {
                        fail("We couldn’t join this tape at its live position. Try again.")
                    }
                }
            } else if seekTask != nil {
                if Date.now.timeIntervalSince(itemLoadedAt) > 45 {
                    fail("We couldn’t reach the live position in this tape. Try again or change channels.")
                }
            } else if player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                if stalledSince == nil { stalledSince = .now }
                isLoading = true
                if let stalledSince, Date.now.timeIntervalSince(stalledSince) > 45 {
                    fail("The Internet Archive stream stopped responding. Try again or change channels.")
                }
            } else {
                stalledSince = nil
                isLoading = false
            }
        @unknown default:
            break
        }
    }

    private func fail(_ message: String) {
        cancelSeek()
        audioPlayer.stop()
        player.pause()
        isLoading = false
        errorMessage = message
    }

    private func cancelSeek() {
        seekTask?.cancel()
        seekTask = nil
        player.currentItem?.cancelPendingSeeks()
    }

    private func metadata(for airing: Airing) -> [AVMetadataItem] {
        let title = AVMutableMetadataItem()
        title.identifier = .commonIdentifierTitle
        title.value = airing.title as NSString
        title.extendedLanguageTag = "und"
        let description = AVMutableMetadataItem()
        description.identifier = .commonIdentifierDescription
        description.value = "CH \(channel?.number ?? 0) · \(channel?.name ?? "Spelunkr") · Live on spelunkr.tv" as NSString
        description.extendedLanguageTag = "und"
        return [title, description]
    }
}
