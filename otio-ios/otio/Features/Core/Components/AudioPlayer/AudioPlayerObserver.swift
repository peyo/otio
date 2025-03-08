import AVFoundation

class AudioPlayerObserver: NSObject {
    private weak var player: AVPlayer?
    private var isObserving = false
    private var timeoutWork: DispatchWorkItem?
    
    var onPlaybackStarted: (() -> Void)?
    var onPlaybackFinished: (() -> Void)?
    var onPlaybackError: ((AudioError) -> Void)?
    
    init(player: AVPlayer?) {
        self.player = player
        super.init()
    }
    
    func setupPlaybackObservers(playerItem: AVPlayerItem) {
        setupTimeoutWork()
        setupNotificationObservers(for: playerItem)
        setupStatusObserver(for: playerItem)
    }
    
    private func setupTimeoutWork() {
        timeoutWork = DispatchWorkItem { [weak self] in
            print("AudioPlayerManager: Playback preparation timed out")
            self?.handlePlaybackError(AudioError.playbackFailed(NSError(
                domain: "AudioPlayerManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Playback preparation timed out"]
            )))
        }
        
        if let timeoutWork = timeoutWork {
            DispatchQueue.main.asyncAfter(deadline: .now() + 15.0, execute: timeoutWork)
        }
    }
    
    private func setupNotificationObservers(for playerItem: AVPlayerItem) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    private func setupStatusObserver(for playerItem: AVPlayerItem) {
        playerItem.addObserver(self, 
            forKeyPath: "status", 
            options: [.new], 
            context: nil)
        isObserving = true
    }
    
    private func handlePlaybackError(_ error: AudioError) {
        print("AudioPlayerManager: \(error.description)")
        cleanup()
        timeoutWork?.cancel()
        timeoutWork = nil
        onPlaybackError?(error)
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("AudioPlayerManager: Audio interrupted")
            player?.pause()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                print("AudioPlayerManager: Resuming audio after interruption")
                player?.play()
            }
        @unknown default:
            break
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        print("AudioPlayerManager: audio finished playing naturally")
        cleanup()
        timeoutWork?.cancel()
        timeoutWork = nil
        onPlaybackFinished?()
    }
    
    override func observeValue(forKeyPath keyPath: String?, 
                             of object: Any?, 
                             change: [NSKeyValueChangeKey : Any]?, 
                             context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let item = object as? AVPlayerItem {
                switch item.status {
                case .readyToPlay:
                    print("AudioPlayerManager: Audio ready to play at \(Date())")
                    // Cancel timeout when audio is ready to play
                    timeoutWork?.cancel()
                    timeoutWork = nil
                    // Notify that audio is ready
                    DispatchQueue.main.async {
                        self.onPlaybackStarted?()
                    }
                case .failed:
                    print("AudioPlayerManager: Audio failed to load")
                    handlePlaybackError(.playbackFailed(item.error ?? NSError(domain: "AudioPlayerManager", code: -1, userInfo: nil)))
                case .unknown:
                    print("AudioPlayerManager: Audio status unknown")
                @unknown default:
                    break
                }
            }
        }
    }
    
    func cleanup() {
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        if isObserving {
            player?.currentItem?.removeObserver(self, forKeyPath: "status")
            isObserving = false
        }
    }
    
    deinit {
        if isObserving {
            player?.currentItem?.removeObserver(self, forKeyPath: "status")
        }
    }
}